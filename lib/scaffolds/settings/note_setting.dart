import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/file_picker_util.dart';
import 'package:flutter_test_future/utils/image_util.dart';

class NoteSetting extends StatefulWidget {
  const NoteSetting({Key? key}) : super(key: key);

  @override
  _NoteSettingState createState() => _NoteSettingState();
}

class _NoteSettingState extends State<NoteSetting> {
  // String imageRootDirPath = ImageUtil.imageRootDirPath;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    // SPUtil.setString("imageWindowsRootDirPath", "");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "笔记设置",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('设置图片根目录'),
            subtitle: Text(ImageUtil.imageRootDirPath),
            onTap: () async {
              String selectIimageRootDirPath = (await selectDirectory()) ?? "";
              if (selectIimageRootDirPath.isNotEmpty) {
                ImageUtil.setImageRootDirPath(selectIimageRootDirPath);
                setState(() {});
              }
            },
          ),
          ListTile(
            title: const Text('注意事项'),
            subtitle: const Text("添加图片后，改变图片路径和重命名会无法显示"),
            onTap: () {},
            trailing: const Icon(Icons.warning_amber_rounded,
                color: Colors.orangeAccent),
          ),
        ],
      ),
    );
  }
}
