import 'dart:io';

import 'package:animetrace/components/dialog/dialog_share_error_log.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/utils/backup_util.dart';
import 'package:animetrace/utils/file_picker_util.dart';
import 'package:animetrace/utils/sp_util.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:animetrace/widgets/setting_card.dart';

class LocalBackupPage extends StatefulWidget {
  const LocalBackupPage({super.key});

  @override
  State<LocalBackupPage> createState() => _LocalBackupPageState();
}

class _LocalBackupPageState extends State<LocalBackupPage> {
  String autoBackupLocal = SPUtil.getBool("auto_backup_local") ? "开启" : "关闭";
  int autoBackupLocalNumber =
      SPUtil.getInt("autoBackupLocalNumber", defaultValue: 20);

  @override
  Widget build(BuildContext context) {
    return SettingCard(
      title: '本地备份',
      children: [
        if (Platform.isWindows)
          ListTile(
            title: const Text("立即备份"),
            subtitle: const Text("单击进行备份，备份目录为设置的本地目录"),
            // subtitle: Text(getDuration()),
            onTap: () {
              // 注意这里是本地手动备份
              ToastUtil.showText("正在备份");
              BackupUtil.backup(
                  localBackupDirPath: SPUtil.getString("backup_local_dir",
                      defaultValue: "unset"));
            },
          ),
        if (Platform.isWindows)
          ListTile(
            title: const Text("本地备份目录"),
            subtitle: Text(SPUtil.getString("backup_local_dir")),
            onTap: () async {
              String? selectedDirectory = await selectDirectory();
              if (selectedDirectory != null) {
                SPUtil.setString("backup_local_dir", selectedDirectory);
                setState(() {});
              }
            },
          ),
        if (Platform.isWindows)
          SwitchListTile(
            title: const Text("自动备份"),
            subtitle: const Text("每次进入应用后会自动备份"),
            value: SPUtil.getBool("auto_backup_local"),
            onChanged: (bool value) {
              if (SPUtil.getString("backup_local_dir", defaultValue: "unset") ==
                  "unset") {
                ToastUtil.showText("请先设置本地备份目录，再进行备份！");
                return;
              }
              if (SPUtil.getBool("auto_backup_local")) {
                // 如果是开启，点击后则关闭
                SPUtil.setBool("auto_backup_local", false);
                autoBackupLocal = "关闭";
              } else {
                SPUtil.setBool("auto_backup_local", true);
                // 开启后先备份一次，防止因为用户没有点击过手动备份，而无法得到上一次备份时间，从而无法求出备份间隔
                // WebDavUtil.backupData(true);
                autoBackupLocal = "开启";
              }
              setState(() {});
            },
          ),
        // 鸿蒙插件未进行适配，暂时隐藏
        // UnimplementedError: The current platform "ohos" is not supported by this plugin.
        if (!Platform.isOhos)
          ListTile(
            title: const Text("还原本地备份"),
            subtitle: const Text("还原动漫记录"),
            onTap: () async {
              // 获取备份文件
              String? selectedFilePath = await selectFile();
              if (selectedFilePath != null) {
                ToastUtil.showLoading(
                  msg: "还原数据中",
                  task: () {
                    return BackupUtil.restoreFromLocal(selectedFilePath);
                  },
                  onTaskSuccess: (taskValue) {
                    ToastUtil.showText(taskValue.msg);
                    if (taskValue.isFailure) {
                      showShareErrorLog();
                    }
                  },
                  onTaskError: (e) {
                    showShareErrorLog();
                  },
                );
              }
            },
          ),
      ],
    );
  }
}
