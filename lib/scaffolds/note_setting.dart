import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/file_picker_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';

class NoteSetting extends StatefulWidget {
  const NoteSetting({Key? key}) : super(key: key);

  @override
  _NoteSettingState createState() => _NoteSettingState();
}

class _NoteSettingState extends State<NoteSetting> {
  String imageRootDirPath =
      SPUtil.getString("imageRootDirPath", defaultValue: "");

  @override
  void dispose() {
    super.dispose();
    // SPUtil.setString("imageRootDirPath", "");
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
              SPUtil.setString("imageRootDirPath", imageRootDirPath);
            },
          ),
        ],
      ),
    );
  }
}
