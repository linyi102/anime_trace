import 'dart:async';

import 'package:flutter/material.dart';
import 'package:animetrace/components/dialog/dialog_select_uint.dart';
import 'package:animetrace/controllers/backup_service.dart';
import 'package:animetrace/controllers/remote_controller.dart';
import 'package:animetrace/pages/anime_collection/checklist_controller.dart';
import 'package:animetrace/pages/settings/backup_file_list.dart';
import 'package:animetrace/pages/settings/backup_restore/home.dart';
import 'package:animetrace/pages/settings/backup_restore/login_form.dart';
import 'package:animetrace/routes/get_route.dart';
import 'package:animetrace/utils/backup_util.dart';
import 'package:animetrace/utils/sp_util.dart';
import 'package:animetrace/utils/webdav_util.dart';
import 'package:animetrace/values/values.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:animetrace/widgets/common_status_prompt.dart';
import 'package:animetrace/widgets/setting_card.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

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

  bool get autoBackupIsOff =>
      backupService.curRemoteBackupMode == BackupMode.close;
  bool get autoBackupIsOn => !autoBackupIsOff;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WebDavUtil.pingWebDav();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SettingCard(
            title: 'WebDav 备份',
            useCard: !widget.fromHome,
            titleStyle: widget.fromHome
                ? Theme.of(context).textTheme.titleMedium
                : null,
            trailing: widget.fromHome
                ? IconButton(
                    color: Theme.of(context).iconTheme.color,
                    splashRadius: 20,
                    onPressed: () {
                      RouteUtil.materialTo(
                          context, const BackupAndRestorePage());
                    },
                    icon: const Icon(MingCuteIcons.mgc_arrow_right_line))
                : null,
            children: [
              GetBuilder(
                init: RemoteController.to,
                builder: (_) => ListTile(
                  title: const Text("登录帐号"),
                  trailing: Icon(
                    Icons.circle,
                    size: 12,
                    color: RemoteController.to.isOnline
                        ? AppTheme.connectableColor
                        : Colors.grey,
                  ),
                  onTap: () {
                    _toWebDavLoginPage();
                  },
                ),
              ),
              ListTile(
                title: const Text("立即备份"),
                subtitle: const Text("点击进行备份，备份目录为 /animetrace"),
                onTap: () async {
                  if (RemoteController.to.isOffline) {
                    ToastUtil.showText("请先配置帐号，再进行备份");
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
                  String remoteBackupDirPath =
                      await WebDavUtil.getRemoteDirPath();
                  if (remoteBackupDirPath.isNotEmpty) {
                    BackupUtil.backup(remoteBackupDirPath: remoteBackupDirPath);
                  }
                },
              ),
              ListTile(
                title: const Text("还原备份"),
                subtitle: const Text("选择备份文件进行还原"),
                onTap: () async {
                  if (RemoteController.to.isOffline) {
                    ToastUtil.showText("请先配置帐号，再进行还原");
                    return;
                  }

                  RouteUtil.materialTo(context, const BackUpFileListPage());
                },
              ),
              _buildAutoBackupPrompt(),
            ],
          ),
          if (!widget.fromHome)
            SettingCard(
              title: '高级配置',
              children: [
                SwitchListTile(
                  title: const Text("自动还原"),
                  subtitle: const Text("进入应用前还原最新数据\n注意：选择「打开应用后自动备份」时不会生效"),
                  value: backupService.enableAutoRestoreFromRemote,
                  onChanged: (value) {
                    backupService.setAutoRestoreFromRemote(value);
                    // 重绘页面
                    setState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text("下拉还原"),
                  subtitle: const Text("动漫收藏页下拉时，会尝试还原最新数据"),
                  value: SPUtil.getBool(
                      pullDownRestoreLatestBackupInChecklistPage),
                  onChanged: (value) {
                    SPUtil.setBool(
                        pullDownRestoreLatestBackupInChecklistPage, value);
                    // 重绘页面
                    setState(() {});
                    // 重绘收藏页，以便于允许或取消下拉刷新
                    ChecklistController.to.update();
                  },
                ),
              ],
            ),
        ],
      ),
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

    return autoBackupIsOff
        ? CommonStatusPrompt(
            icon: const Icon(Icons.cloud_off),
            titleText: '自动备份未开启',
            subtitleText: '开启自动备份后，可在打开应用时或关闭应用前自动进行备份',
            buttonText: '开启自动备份',
            onTapButton: () {
              backupService.setBackupMode(BackupMode.backupAfterOpenApp.name);
              setState(() {});
            },
          )
        : CommonStatusPrompt(
            icon: Icon(Icons.cloud_outlined,
                color: Theme.of(context).colorScheme.primary),
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

  void _toWebDavLoginPage() async {
    await RouteUtil.materialTo(context, const WebDavLoginForm());
    setState(() {});
  }
}
