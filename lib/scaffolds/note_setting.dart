import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/file_picker_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';

class NoteSetting extends StatefulWidget {
  const NoteSetting({Key? key}) : super(key: key);

  @override
  _NoteSettingState createState() => _NoteSettingState();
}

class _NoteSettingState extends State<NoteSetting> {
  late String imageRootDirPath;

  @override
  void dispose() {
    super.dispose();
    // SPUtil.setString("imageWindowsRootDirPath", "");
    if (Platform.isAndroid) {
      imageRootDirPath =
          SPUtil.getString("imageWindowsRootDirPath", defaultValue: "");
    } else if (Platform.isWindows) {
      imageRootDirPath =
          SPUtil.getString("imageAndroidRootDirPath", defaultValue: "");
    } else {
      throw ("未适配平台：${Platform.operatingSystem}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "笔记设置",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('图片根目录'),
            subtitle: Text(imageRootDirPath),
            onTap: () async {
              imageRootDirPath = (await selectDirectory()) ?? "";
              setState(() {});
              SPUtil.setString("imageWindowsRootDirPath", imageRootDirPath);
            },
          ),
        ],
      ),
    );
  }
}
