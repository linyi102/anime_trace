import 'dart:io';

import 'package:file/local.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/file_utils/file_picker_util.dart';
import 'package:flutter_test_future/file_utils/sp_util.dart';
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
