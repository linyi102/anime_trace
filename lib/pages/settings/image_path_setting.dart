import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/file_picker_util.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';

class ImagePathSetting extends StatefulWidget {
  const ImagePathSetting({Key? key}) : super(key: key);

  @override
  _ImagePathSettingState createState() => _ImagePathSettingState();
}

class _ImagePathSettingState extends State<ImagePathSetting> {
  bool dirChanged = false; // 用于返回上一级页面，收到true后会更新状态

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
    // 返回键
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(dirChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          // 隐藏自带的返回按钮
          automaticallyImplyLeading: false,
          // 返回按钮
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop(dirChanged);
            },
            icon: const Icon(Icons.arrow_back_outlined),
          ),
          title: const Text(
            "图片设置",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: ListView(
          children: [
            ListTile(
              title: const Text('设置笔记图片所在目录'),
              subtitle: Text(ImageUtil.noteImageRootDirPath),
              onTap: () async {
                String selectImageRootDirPath = (await selectDirectory()) ?? "";
                if (selectImageRootDirPath.isNotEmpty) {
                  ImageUtil.setNoteImageRootDirPath(selectImageRootDirPath);
                  setState(() {});
                  dirChanged = true;
                }
              },
            ),
            ListTile(
              title: const Text('设置封面图片所在目录'),
              subtitle: Text(ImageUtil.coverImageRootDirPath),
              onTap: () async {
                String selectImageRootDirPath = (await selectDirectory()) ?? "";
                if (selectImageRootDirPath.isNotEmpty) {
                  ImageUtil.setCoverImageRootDirPath(selectImageRootDirPath);
                  setState(() {});
                  dirChanged = true;
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
                  "https://www.yuque.com/linyi517/fzfxr0/xpx4xq"),
              trailing: const Icon(Icons.launch),
            ),
            ListTile(
              title: const Text(
                '注意事项',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text("添加图片后，请不要修改图片文件的名称，否则无法显示"),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
