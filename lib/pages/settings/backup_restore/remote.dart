import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/controllers/backup_service.dart';
import 'package:flutter_test_future/pages/anime_collection/checklist_controller.dart';
import 'package:flutter_test_future/pages/settings/backup_file_list.dart';
import 'package:flutter_test_future/pages/settings/backup_restore/login_form.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/widgets/setting_title.dart';

class RemoteBackupPage extends StatefulWidget {
  const RemoteBackupPage({
    Key? key,
    this.fromHome = false,
  }) : super(key: key);
  final bool fromHome;

  @override
  State<RemoteBackupPage> createState() => _RemoteBackupPageState();
}

class _RemoteBackupPageState extends State<RemoteBackupPage> {
  int autoBackupWebDavNumber =
      SPUtil.getInt("autoBackupWebDavNumber", defaultValue: 20);
  bool canManualBackup = true;

  BackupService get backupService => BackupService.to;
  bool get isOnline => SPUtil.getBool("online");

  bool get _autoBackupIsOff =>
      backupService.curRemoteBackupMode == BackupMode.close;
  bool get _autoBackupIsOn => !_autoBackupIsOff;

  @override
  void initState() {
    super.initState();
    // SPUtil.clear();
    // 获取最新情况，更新SP中的online
    WebDavUtil.pingWebDav().then((pingOk) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingTitle(
          title: 'WebDav备份',
          trailing: IconButton(
              onPressed: () {
                LaunchUrlUtil.launch(
                    context: context,
                    uriStr: "https://help.jianguoyun.com/?p=2064");
              },
              splashRadius: 20,
              icon: const Icon(Icons.help_outline, size: 20)),
        ),
        ListTile(
          title: const Text("账号配置"),
          trailing: Icon(
            Icons.circle,
            size: 12,
            color: isOnline ? AppTheme.connectableColor : Colors.grey,
          ),
          onTap: () {
            _loginWebDav();
          },
        ),
        ListTile(
          title: const Text("立即备份"),
          subtitle: const Text("点击进行备份，备份目录为 /animetrace"),
          onTap: () async {
            if (!SPUtil.getBool("login")) {
              ToastUtil.showText("请先配置账号，再进行备份！");
              return;
            }

            if (!canManualBackup) {
              ToastUtil.showText("备份间隔为10s");
              return;
            }

            canManualBackup = false;
            Future.delayed(const Duration(seconds: 10))
                .then((value) => canManualBackup = true);

            ToastUtil.showText("正在备份");
            String remoteBackupDirPath = await WebDavUtil.getRemoteDirPath();
            if (remoteBackupDirPath.isNotEmpty) {
              BackupUtil.backup(remoteBackupDirPath: remoteBackupDirPath);
            }
          },
        ),
        ListTile(
          title: const Text("还原备份"),
          subtitle: const Text("选择备份文件进行还原"),
          onTap: () async {
            if (isOnline) {
              showModalBottomSheet(
                // 主页打开底部面板再次打开底部面板时，不再指定barrierColor颜色，避免不透明度加深
                barrierColor: widget.fromHome ? Colors.transparent : null,
                context: context,
                builder: (context) => const BackUpFileListPage(),
              ).then((value) {
                setState(() {});
              });
            } else {
              ToastUtil.showText("配置账号后才可以进行还原");
            }
          },
        ),
        _buildAutoBackupPrompt(),
        if (!widget.fromHome)
          SwitchListTile(
            title: const Text("自动还原"),
            subtitle: const Text("进入应用前还原最新备份文件\n若选择打开应用后自动备份，则该功能不会生效"),
            value: backupService.enableAutoRestoreFromRemote,
            onChanged: (value) {
              backupService.setAutoRestoreFromRemote(value);
              // 重绘页面
              setState(() {});
            },
          ),
        if (!widget.fromHome)
          SwitchListTile(
            title: const Text("下拉还原"),
            subtitle: const Text("动漫收藏页下拉时，会尝试还原最新备份文件"),
            value: SPUtil.getBool(pullDownRestoreLatestBackupInChecklistPage),
            onChanged: (value) {
              SPUtil.setBool(pullDownRestoreLatestBackupInChecklistPage, value);
              // 重绘页面
              setState(() {});
              // 重绘收藏页，以便于允许或取消下拉刷新
              ChecklistController.to.update();
            },
          ),
        const SizedBox(height: 50),
      ],
    );
  }

  void _handleSelectAutoBackupNumber() async {
    int? number = await dialogSelectUint(context, "备份数量",
        initialValue: autoBackupWebDavNumber, minValue: 10, maxValue: 20);
    if (number != null) {
      autoBackupWebDavNumber = number;
      SPUtil.setInt("autoBackupWebDavNumber", number);
      setState(() {});
    }
  }

  _buildAutoBackupPrompt() {
    const configTitleStyle = TextStyle(fontSize: 14);
    final configSubtitleStyle = TextStyle(
      fontSize: 13,
      color: Theme.of(context).hintColor,
    );

    return _autoBackupIsOff
        ? CommonStatusPrompt(
            icon: Icons.cloud_off,
            titleText: '自动备份未开启',
            subtitleText: '开启自动备份后，可在打开应用时或关闭应用前自动进行备份',
            buttonText: '开启自动备份',
            onTapButton: () {
              backupService.setBackupMode(BackupMode.backupAfterOpenApp.name);
              setState(() {});
            },
          )
        : CommonStatusPrompt(
            icon: Icons.cloud_outlined,
            titleText: '自动备份已开启',
            // subtitleText: '开启自动备份后，可在打开应用时或关闭应用前自动进行备份',
            subtitle: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    _handleSelectAutoBackupMode();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
                    child: Row(
                      children: [
                        const Text("备份时机", style: configTitleStyle),
                        const Spacer(),
                        Row(
                          children: [
                            Text(backupService.curRemoteBackupMode.title,
                                style: configSubtitleStyle),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    _handleSelectAutoBackupNumber();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Row(
                      children: [
                        const Text("备份数量", style: configTitleStyle),
                        const Spacer(),
                        Text("$autoBackupWebDavNumber",
                            style: configSubtitleStyle),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            buttonText: '关闭自动备份',
            onTapButton: () {
              backupService.setBackupMode(BackupMode.close.name);
              setState(() {});
            },
          );
  }

  Future<dynamic> _handleSelectAutoBackupMode() {
    return showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("备份时机"),
        children: [
          for (int i = 0; i < BackupMode.values.length; ++i)
            BackupMode.values[i] == BackupMode.close
                ? const SizedBox()
                : RadioListTile(
                    title: Text(BackupMode.values[i].title),
                    value: BackupMode.values[i].name,
                    groupValue: backupService.curRemoteBackupModeName,
                    onChanged: (String? value) {
                      if (value == null) return;

                      backupService.setBackupMode(value);
                      // 关闭对话框
                      Navigator.pop(context);
                      // 重绘页面
                      setState(() {});
                    }),
        ],
      ),
    );
  }

  void _loginWebDav() async {
    await showDialog(
      context: context,
      builder: (context) => const WebDavLoginForm(),
    );
    setState(() {});
  }
}

class CommonStatusPrompt extends StatelessWidget {
  const CommonStatusPrompt({
    super.key,
    required this.icon,
    required this.titleText,
    this.subtitleText,
    this.subtitle,
    required this.buttonText,
    required this.onTapButton,
  });
  final IconData icon;
  final String titleText;
  final String? subtitleText;
  final Widget? subtitle;
  final String buttonText;
  final void Function() onTapButton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 30, 0),
            child: Icon(icon),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titleText,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                if (subtitleText != null)
                  Text(
                    subtitleText!,
                    style: TextStyle(
                        fontSize: 14, color: Theme.of(context).hintColor),
                  ),
                if (subtitle != null) subtitle!,
                const SizedBox(height: 10),
                ElevatedButton(onPressed: onTapButton, child: Text(buttonText))
              ],
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}
