import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:get/get.dart';

enum BackupMode {
  close("关闭", 0),
  period1s("每隔1秒备份", 1),
  period2s("每隔2秒备份", 2),
  period10m("每隔10分钟备份", 10 * 60),
  backupBeforeExitApp("关闭应用前备份", 0),
  ;

  final String title;
  final int intervalSeconds;
  const BackupMode(this.title, this.intervalSeconds);
}

class BackupService extends GetxService {
  static BackupService get to => Get.find();

  String curRemoteBackupModeName = SPUtil.getString("curRemoteBackupModeName",
      defaultValue: BackupMode.close.name);
  BackupMode get curRemoteBackupMode =>
      getBackupModeByName(curRemoteBackupModeName);

  bool enableAutoRestoreFromRemote =
      SPUtil.getBool("enableAutoRestoreFromRemote", defaultValue: false);

  Timer? backupTimer;

  /// 开启服务
  startService() async {
    // 如果开启了本地备份
    if (SPUtil.getBool("auto_backup_local")) {
      Log.info("准备本地自动备份");
      BackupUtil.backup(
        localBackupDirPath:
            SPUtil.getString("backup_local_dir", defaultValue: "unset"),
        showToastFlag: false,
        automatic: true,
      );
    }

    // 之前登录过，因为关闭应用会导致连接关闭，所以下次重启应用时需要再次连接
    if (SPUtil.getBool("login")) {
      await WebDavUtil.initWebDav(
        SPUtil.getString("webdav_uri"),
        SPUtil.getString("webdav_user"),
        SPUtil.getString("webdav_password"),
      );
    }

    // 如果开启了远程间隔备份
    if (curRemoteBackupMode.intervalSeconds > 0) {
      startTimer(curRemoteBackupMode);
    }

    // 如果开启了远程还原
    if (enableAutoRestoreFromRemote) {
      bool needRestore = true;
      var latestBackupFile = await BackupUtil.getLatestBackupFile();
      if (latestBackupFile == null || latestBackupFile.cTime == null) {
        // 没有最新文件，或最新文件没有时间，或不进行还原
        needRestore = false;
      } else if (latestBackupFile.cTime!.millisecondsSinceEpoch <=
          File(SqliteUtil.dbPath).statSync().modified.millisecondsSinceEpoch) {
        needRestore = false;
      }
      needRestore = true;

      if (needRestore) {
        Log.info("自动还原最新数据");
        ToastUtil.showLoading(
          msg: "正在还原最新数据",
          task: () async {
            await Future.delayed(const Duration(seconds: 2));

            if (latestBackupFile!.cTime!.millisecondsSinceEpoch >
                File(SqliteUtil.dbPath)
                    .statSync()
                    .modified
                    .millisecondsSinceEpoch) {
              // 判断最新远程备份文件和本地数据库文件的修改时间，如果远程大，说明远程比本地新，此时进行还原
              return false;

              // ToastUtil.showLoading(
              //   msg: "还原数据中",
              //   task: () {
              //     return BackupUtil.restoreFromWebDav(latestBackupFile);
              //   },
              //   onTaskComplete: (taskValue) {
              //     taskValue as Result;
              //     ToastUtil.showText(taskValue.msg);
              //   },
              // );
            }
          },
          onTaskComplete: (taskValue) {
            if (false) {
              // 还原失败
              ToastUtil.showDialog(
                builder: (cancel) => AlertDialog(
                  title: const Text("还原失败"),
                  actions: [
                    TextButton(
                        onPressed: () => cancel(), child: const Text("关闭"))
                  ],
                ),
              );
            } else {
              // 还原成功
              ToastUtil.showText("已还原最新备份");
              // 重绘动漫收藏页，显示最新添加的动漫
            }
          },
        );
      }
    }
  }

  /// 开启间隔备份
  /// 打开App时调用；切换备份方式为间隔备份时调用
  startTimer(BackupMode mode) {
    Log.info("开启间隔备份定时器");
    // 切换时也要关闭之前的定时器
    backupTimer?.cancel();
    // 开启定时器
    backupTimer = Timer.periodic(
      Duration(seconds: mode.intervalSeconds),
      (timer) async {
        Log.info("自动备份(间隔${mode.intervalSeconds}s)");
        // BackupUtil.backup(
        //   remoteBackupDirPath: await WebDavUtil.getRemoteDirPath(),
        //   showToastFlag: false,
        //   automatic: true,
        // );
      },
    );
  }

  /// 指定备份方式
  setBackupMode(String name) {
    curRemoteBackupModeName = name;
    SPUtil.setString("curRemoteBackupModeName", name);

    var mode = getBackupModeByName(name);
    if (mode.intervalSeconds > 0) {
      startTimer(mode);
    } else {
      // 关闭定时器
      backupTimer?.cancel();
    }
  }

  BackupMode getBackupModeByName(String name) {
    int idx = BackupMode.values.indexWhere((element) => element.name == name);
    if (idx > 0) {
      return BackupMode.values[idx];
    } else {
      return BackupMode.close;
    }
  }

  /// 设置打开app时是否自动还原远程最新备份
  setAutoRestoreFromRemote(bool value) {
    enableAutoRestoreFromRemote = value;
    SPUtil.setBool("enableAutoRestoreFromRemote", value);
  }

  tryBackupBeforeExitApp({required Function exitApp}) async {
    if (curRemoteBackupMode == BackupMode.backupBeforeExitApp) {
      Log.info("退出App前进行远程备份");
      ToastUtil.showLoading(
        msg: "正在备份数据",
        clickClose: false,
        task: () async {
          await Future.delayed(const Duration(seconds: 2));
          return false;
        },
        onTaskComplete: (taskValue) {
          if (taskValue) {
            // 备份成功，直接退出app
            exitApp();
          } else {
            // 备份失败，弹出对话框
            ToastUtil.showDialog(
              builder: (cancel) => AlertDialog(
                title: const Text("备份失败"),
                actions: [
                  TextButton(
                      onPressed: () {
                        // 关闭对啊户口
                        cancel();
                        // 重新备份
                        tryBackupBeforeExitApp(exitApp: exitApp);
                      },
                      child: const Text("重试")),
                  TextButton(
                      onPressed: () => exitApp(), child: const Text("退出")),
                ],
              ),
            );
          }
        },
      );
    } else {
      // 没有开启退出app备份，那么就直接退出
      exitApp();
    }
  }
}
