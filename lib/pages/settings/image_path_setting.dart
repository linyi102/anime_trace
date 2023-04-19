import 'package:flutter/material.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/utils/file_picker_util.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';

class ImagePathSetting extends StatefulWidget {
  const ImagePathSetting({Key? key}) : super(key: key);

  @override
  _ImagePathSettingState createState() => _ImagePathSettingState();
}

class _ImagePathSettingState extends State<ImagePathSetting> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("图片设置")),
      body: ListView(
        children: [
          ListTile(
            title: const Text('本地笔记图片存放目录'),
            subtitle: Text(ImageUtil.noteImageRootDirPath),
            onTap: () async {
              String selectImageRootDirPath = (await selectDirectory()) ?? "";
              if (selectImageRootDirPath.isNotEmpty) {
                ImageUtil.setNoteImageRootDirPath(selectImageRootDirPath);
                setState(() {});
                Global.modifiedImgRootPath = true;
              }
            },
          ),
          ListTile(
            title: const Text('本地封面图片存放目录'),
            subtitle: Text(ImageUtil.coverImageRootDirPath),
            onTap: () async {
              String selectImageRootDirPath = (await selectDirectory()) ?? "";
              if (selectImageRootDirPath.isNotEmpty) {
                ImageUtil.setCoverImageRootDirPath(selectImageRootDirPath);
                setState(() {});
                Global.modifiedImgRootPath = true;
              }
            },
          ),
          const Divider(),
          ListTile(
            title: const Text(
              '无法显示图片',
            ),
            subtitle: const Text("点击查看使用帮助"),
            onTap: () => LaunchUrlUtil.launch(
                context: context,
                uriStr: "https://www.yuque.com/linyi517/fzfxr0/xpx4xq"),
            trailing: const Icon(Icons.launch),
          ),
          ListTile(
            title: Text(
              '注意事项',
              style: TextStyle(color: Theme.of(context).errorColor),
            ),
            subtitle: const Text("添加图片后，请不要修改图片文件的名称，否则无法显示"),
          ),
        ],
      ),
    );
  }
}
