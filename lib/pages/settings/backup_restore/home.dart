import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/settings/backup_restore/local.dart';
import 'package:flutter_test_future/pages/settings/backup_restore/remote.dart';
import 'package:flutter_test_future/pages/settings/pages/rbr_page.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/widgets/bottom_sheet.dart';
import 'package:flutter_test_future/widgets/common_divider.dart';
import 'package:flutter_test_future/widgets/common_scaffold_body.dart';

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
        children: [
          _buildRevokeRestoreTile(),
          const CommonDivider(),
          const LocalBackupPage(),
          const CommonDivider(),
          const RemoteBackupPage(),
        ],
      )),
    );
  }

  ListTile _buildRevokeRestoreTile() {
    return ListTile(
      title: const Text("撤销还原"),
      subtitle: const Text("点击查看还原前的记录"),
      onTap: () {
        showCommonModalBottomSheet(
            context: context, builder: (context) => const RBRPage());
      },
      trailing: IconButton(
          onPressed: _showHelpDialog,
          splashRadius: 20,
          icon: const Icon(Icons.help_outline, size: 20)),
    );
  }

  Future<dynamic> _showHelpDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("帮助"),
        content: Text("用户在还原数据前，会记录当前的数据，存放在这里。\n"
            "当用户在还原数据后，如果想要撤销还原，可以在这里恢复之前的数据。\n"
            "注：最多会存放${BackupUtil.rbrMaxCnt}份，超出时会删除旧的。"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("我已了解"))
        ],
      ),
    );
  }
}
