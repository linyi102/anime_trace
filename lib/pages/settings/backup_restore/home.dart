import 'dart:io';

import 'package:flutter/material.dart';
import 'package:animetrace/pages/settings/backup_restore/local.dart';
import 'package:animetrace/pages/settings/backup_restore/remote.dart';
import 'package:animetrace/pages/settings/pages/rbr_page.dart';
import 'package:animetrace/routes/get_route.dart';
import 'package:animetrace/utils/backup_util.dart';
import 'package:animetrace/widgets/common_scaffold_body.dart';
import 'package:animetrace/widgets/setting_card.dart';

class BackupAndRestorePage extends StatefulWidget {
  const BackupAndRestorePage({Key? key}) : super(key: key);

  @override
  _BackupAndRestorePageState createState() => _BackupAndRestorePageState();
}

class _BackupAndRestorePageState extends State<BackupAndRestorePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("备份还原")),
      body: CommonScaffoldBody(
          child: ListView(
        padding: const EdgeInsets.only(bottom: 50),
        children: [
          // 鸿蒙file_picker包选择文件未进行适配，暂时隐藏
          // UnimplementedError: The current platform "ohos" is not supported by this plugin.
          if (!Platform.isOhos) const LocalBackupPage(),
          const RemoteBackupPage(),
          SettingCard(
            title: '撤销还原',
            children: [
              _buildRevokeRestoreTile(),
            ],
          ),
        ],
      )),
    );
  }

  ListTile _buildRevokeRestoreTile() {
    return ListTile(
      title: const Text("还原前的备份记录"),
      onTap: () {
        RouteUtil.materialTo(context, const RBRPage());
      },
      trailing: IconButton(
          onPressed: _showHelpDialog, icon: const Icon(Icons.help_outline)),
    );
  }

  Future<dynamic> _showHelpDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("帮助"),
        content: Text("用户在还原数据前，会备份当前的数据，存放在此处。\n"
            "当用户在还原数据后，如果想要撤销还原，可以在这里恢复之前的数据。\n"
            "注：最多会存放 ${BackupUtil.rbrMaxCnt} 份，超出时会删除旧备份。"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("我已了解"))
        ],
      ),
    );
  }
}
