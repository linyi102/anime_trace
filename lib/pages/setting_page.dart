import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/file_picker_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:path_provider/path_provider.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const ListTile(
            title: Text("创建备份"),
          ),
          const ListTile(
            title: Text("还原备份"),
          ),
          const Divider(),
          ListTile(
            title: const Text("备份路径"),
            subtitle: Text(SPUtil.getString("backup_path")),
            onTap: () async {
              selectDirectory().then((value) {
                SPUtil.setString("backup_path", value);
                setState(() {});
              });
            },
          ),
          FloatingActionButton(
            onPressed: () async {
              final dir = await getExternalStorageDirectory();
              debugPrint(dir!.path);
            },
            child: const Icon(Icons.ac_unit),
          ),
        ],
      ),
    );
  }
}
