import 'dart:io';

import 'package:animetrace/utils/toast_util.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/global.dart';
import 'package:animetrace/utils/file_picker_util.dart';
import 'package:animetrace/utils/image_util.dart';
import 'package:animetrace/utils/launch_uri_util.dart';
import 'package:animetrace/widgets/common_scaffold_body.dart';
import 'package:animetrace/widgets/setting_card.dart';
import 'package:permission_handler/permission_handler.dart';

class ImagePathSetting extends StatefulWidget {
  const ImagePathSetting({Key? key}) : super(key: key);

  @override
  _ImagePathSettingState createState() => _ImagePathSettingState();
}

class _ImagePathSettingState extends State<ImagePathSetting> {
  bool hasReadImagePerm = false;
  Permission? imagePerm;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      imagePerm = androidInfo.version.sdkInt <= 32
          ? Permission.storage
          : Permission.photos;
      _getReadImagePerm();
    }
  }

  void _getReadImagePerm() async {
    hasReadImagePerm = await imagePerm!.status.isGranted;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("图片设置")),
      body: CommonScaffoldBody(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!FeatureFlag.enableSelectLocalImage) {
      return const Center(
        child: Text('暂不支持进行图片设置'),
      );
    }
    return ListView(
      children: [
        SettingCard(
          title: '根目录设置',
          children: [
            if (imagePerm != null)
              ListTile(
                title: const Text('读取图片权限'),
                subtitle: const Text('未授权时应用会无法访问图片'),
                trailing: TextButton(
                  onPressed: () async {
                    if (hasReadImagePerm) return;

                    final r = await imagePerm!.request();
                    if (r.isDenied) {
                      ToastUtil.showText('权限被拒绝');
                    } else if (r.isGranted) {
                      ToastUtil.showText('权限成功');
                    }
                    _getReadImagePerm();
                  },
                  child: Text(hasReadImagePerm ? '已授权' : '去授权'),
                ),
              ),
            ListTile(
              title: const Text('本地笔记图片存放目录'),
              subtitle: Text(ImageUtil.noteImageRootDirPath.isEmpty
                  ? '单击选择目录'
                  : ImageUtil.noteImageRootDirPath),
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
              subtitle: Text(ImageUtil.coverImageRootDirPath.isEmpty
                  ? '单击选择目录'
                  : ImageUtil.coverImageRootDirPath),
              onTap: () async {
                String selectImageRootDirPath = (await selectDirectory()) ?? "";
                if (selectImageRootDirPath.isNotEmpty) {
                  ImageUtil.setCoverImageRootDirPath(selectImageRootDirPath);
                  setState(() {});
                  Global.modifiedImgRootPath = true;
                }
              },
            ),
          ],
        ),
        SettingCard(
          title: '帮助',
          children: [
            ListTile(
              title: const Text('无法显示图片？'),
              subtitle: const Text("点击查看使用帮助"),
              onTap: () => LaunchUrlUtil.launch(
                  context: context,
                  uriStr: "https://www.yuque.com/linyi517/fzfxr0/xpx4xq"),
              trailing: const Icon(Icons.open_in_new_rounded),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 5),
              Text(
                "在笔记中添加图片后，请不要移动图片或修改图片名称，否则无法显示。",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
