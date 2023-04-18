import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/params/result.dart';
import 'package:flutter_test_future/pages/anime_collection/checklist_controller.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:get/get.dart';

enum BackupMode {
  close("关闭", 0),
  backupAfterOpenApp("打开应用后备份", 0),
  // period1s("每隔1秒备份", 1),
  // period2s("每隔2秒备份", 2),
  // period10m("每隔10分钟备份", 10 * 60),
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
    // 兼容低版本，如果低版本开启过远程自动备份，则切换为现在的打开App后自动备份模式，然后删除该key
    if (SPUtil.getBool("auto_backup_webdav")) {
      setBackupMode(BackupMode.backupAfterOpenApp.name);
      SPUtil.remove("auto_backup_webdav");
    }

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

    // 如果设置为打开时备份
    if (curRemoteBackupModeName == BackupMode.backupAfterOpenApp.name) {
      Log.info("准备dav自动备份");
      BackupUtil.backup(
        remoteBackupDirPath: await WebDavUtil.getRemoteDirPath(),
        showToastFlag: false,
        automatic: true,
      );
    }
    // 如果设置为打开时还原远程最新数据
    else if (enableAutoRestoreFromRemote) {
      tryRestoreRemoteFile();
    }
  }

  tryRestoreRemoteFile() async {
    bool needRestore = false;
    var latestBackupFile = await BackupUtil.getLatestBackupFile();
    if (latestBackupFile == null || latestBackupFile.mTime == null) {
      // 没有最新文件，或最新文件没有时间，或不进行还原
      ToastUtil.showText("dav中没有找到最新备份");
    } else if (latestBackupFile.path ==
        SPUtil.getString(latestDavBackupFilePath)) {
      // 如果是上次该设备手动/自动备份文件，则不需要还原
      ToastUtil.showText("已是最新数据，无需还原");
    } else {
      // 判断最新远程备份文件和本地数据库文件的修改时间，如果远程大，说明远程比本地新，此时进行还原
      var latestDT = latestBackupFile.mTime!;
      var localDT = File(SqliteUtil.dbPath).statSync().modified;
      Log.info("最新备份的修改时间：$latestDT，本地数据文件的修改时间：$localDT");

      // 如果不进行时间判断，那么如果App在后台被清理导致没有备份，那么重启App是就会进行还原，从而导致数据丢失
      if (latestDT.compareTo(localDT) > 0) {
        needRestore = true;
      } else {
        ToastUtil.showText("已是最新数据，无需还原");
      }
    }

    if (needRestore) {
      restoreRemoteFile(latestBackupFile);
    }
  }

  restoreRemoteFile(latestBackupFile) {
    Log.info("自动还原最新数据");
    ToastUtil.showLoading(
      msg: "正在还原最新数据",
      task: () async {
        return BackupUtil.restoreFromWebDav(latestBackupFile);
      },
      onTaskComplete: (taskValue) {
        taskValue as Result;
        if (taskValue.code != 200) {
          // 还原失败
          ToastUtil.showDialog(
            builder: (cancel) => AlertDialog(
              title: const Text("还原失败"),
              content: Text(taskValue.msg),
              actions: [
                TextButton(onPressed: () => cancel(), child: const Text("关闭")),
                TextButton(
                    onPressed: () {
                      cancel();
                      restoreRemoteFile(latestBackupFile);
                    },
                    child: const Text("重试")),
              ],
            ),
          );
        } else {
          // 还原成功
          ToastUtil.showText("已还原最新备份");
          // 重绘动漫收藏页，显示最新添加的动漫
          ChecklistController.to.restore();
        }
      },
    );
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

  int clickCloseCnt = 0;

  tryBackupBeforeExitApp(
      {required Function exitApp, bool retry = false}) async {
    // 对于Windows端，如果点击关闭后，再次点击关闭时不再进行备份，而是直接退出应用
    // 若是备份失败后点击重试，则再次尝试备份
    if (clickCloseCnt > 0 && !retry) {
      exitApp();
      return;
    }

    if (curRemoteBackupMode == BackupMode.backupBeforeExitApp) {
      clickCloseCnt++;
      Log.info("退出App前进行远程备份");
      ToastUtil.showLoading(
        msg: "正在备份数据",
        clickClose: false,
        task: () async {
          // await Future.delayed(const Duration(seconds: 2));
          return BackupUtil.autoBackupRemote();
        },
        onTaskComplete: (taskValue) {
          taskValue as Result;
          if (taskValue.code == 200) {
            // 备份成功，直接退出app
            exitApp();
          } else {
            // 备份失败，弹出对话框
            ToastUtil.showDialog(
              builder: (cancel) => AlertDialog(
                title: const Text("备份失败"),
                content: Text(taskValue.msg),
                actions: [
                  TextButton(
                      onPressed: () {
                        // 关闭对话框
                        cancel();
                        // 重新备份
                        tryBackupBeforeExitApp(exitApp: exitApp, retry: true);
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
