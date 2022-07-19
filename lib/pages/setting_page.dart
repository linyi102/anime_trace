import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/settings/about_version.dart';
import 'package:flutter_test_future/scaffolds/settings/anime_display_setting.dart';
import 'package:flutter_test_future/scaffolds/settings/backup_restore.dart';
import 'package:flutter_test_future/scaffolds/settings/note_setting.dart';
import 'package:flutter_test_future/scaffolds/settings/tag_manage.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:get/get.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  File? _imgFile;
  bool _loadOk = false;

  @override
  void initState() {
    super.initState();
    String imgFilePath = SPUtil.getString("img_file_path");
    if (imgFilePath.isNotEmpty) {
      _imgFile = File(imgFilePath);
    }
    Future.delayed(const Duration(milliseconds: 0)).then((value) {
      _loadOk = true;
      setState(() {});
    });
  }

  @override
  void dispose() {
    // SPUtil.setString("img_file_path", "");
    super.dispose();
  }

  final ThemeController themeController = Get.find();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "更多",
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildBody(),
        ));
  }

  _buildBody() {
    if (!_loadOk) {
      return Container(
        key: UniqueKey(),
      );
    }
    return Obx(() => ListView(
          children: [
            _showImg(),
            _showImgButton(),
            ListTile(
              iconColor: ThemeUtil.getLeadingIconColor(),
              leading: const Icon(Icons.settings_backup_restore_outlined),
              title: const Text("备份还原"),
              onTap: () {
                Navigator.of(context).push(
                  // MaterialPageRoute(
                  //     builder: (BuildContext context) =>
                  //         const BackupAndRestore()),
                  FadeRoute(
                    builder: (context) {
                      return const BackupAndRestore();
                    },
                  ),
                );
              },
            ),
            // const Divider(),
            ListTile(
              iconColor: ThemeUtil.getLeadingIconColor(),
              leading: const Icon(Icons.new_label_outlined),
              title: const Text("标签管理"),
              onTap: () {
                Navigator.of(context).push(
                  // MaterialPageRoute(
                  //     builder: (BuildContext context) =>
                  //         const TagManage()),
                  FadeRoute(
                    builder: (context) {
                      return const TagManage();
                    },
                  ),
                );
              },
            ),
            ListTile(
              iconColor: ThemeUtil.getLeadingIconColor(),
              leading: const Icon(Icons.book_outlined),
              title: const Text("动漫界面"),
              onTap: () {
                Navigator.of(context).push(
                  // MaterialPageRoute(
                  //     builder: (BuildContext context) =>
                  //         const AnimesDisplaySetting()),
                  FadeRoute(
                    builder: (context) {
                      return const AnimesDisplaySetting();
                    },
                  ),
                );
              },
            ),
            ListTile(
              iconColor: ThemeUtil.getLeadingIconColor(),
              leading: const Icon(Icons.edit_road),
              title: const Text("笔记设置"),
              onTap: () {
                Navigator.of(context).push(
                  // MaterialPageRoute(
                  //     builder: (BuildContext context) =>
                  //         const NoteSetting()),
                  FadeRoute(
                    builder: (context) {
                      return const NoteSetting();
                    },
                  ),
                );
              },
            ),
            ListTile(
              iconColor: ThemeUtil.getLeadingIconColor(),
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text("夜间模式"),
              trailing: themeController.isDarkMode.value
                  ? Icon(Icons.toggle_on,
                      color: ThemeUtil.getThemePrimaryColor(), size: 32)
                  : const Icon(Icons.toggle_off, color: Colors.grey, size: 32),
              onTap: () => themeController.changeTheme(),
            ),
            ListTile(
              iconColor: ThemeUtil.getLeadingIconColor(),
              leading: const Icon(Icons.error_outline),
              title: const Text("关于版本"),
              onTap: () {
                Navigator.of(context).push(
                  // MaterialPageRoute(
                  //     builder: (BuildContext context) =>
                  //         const AboutVersion()),
                  FadeRoute(
                    builder: (context) {
                      return const AboutVersion();
                    },
                  ),
                );
              },
            ),
            // ListTile(
            //   iconColor: ThemeUtil.getLeadingIconColor(),
            //   leading: const Icon(Icons.bug_report_outlined),
            //   title: const Text("测试页面"),
            //   onTap: () {
            //     Navigator.of(context).push(
            //       FadeRoute(
            //         builder: (context) {
            //           return const TestPage();
            //         },
            //       ),
            //     );
            //   },
            // )
          ],
        ));
  }

  _showImg() {
    return _imgFile == null
        ? Container()
        : GestureDetector(
            onDoubleTap: () {
              _removeImage();
            },
            child: SizedBox(
              height: MediaQuery.of(context).size.height / 4,
              width: MediaQuery.of(context).size.width,
              child: Card(
                elevation: 5,
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5))), // 圆角
                clipBehavior: Clip.antiAlias, // 设置抗锯齿，实现圆角背景
                // elevation: 0,
                // margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: Image.file(
                  _imgFile as File,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          );
  }

  _showImgButton() {
    return ListTile(
      iconColor: ThemeUtil.getLeadingIconColor(),
      leading: const Icon(
          // Icons.image_outlined,
          // Icons.wallpaper_outlined,
          Icons.perm_media_outlined),
      title: const Text("设置图片"),
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom, allowedExtensions: ["jpg", "png", "gif"]);
        if (result != null) {
          PlatformFile imgae = result.files.single;
          String path = imgae.path as String;
          SPUtil.setString("img_file_path", path);
          _imgFile = File(path);
          setState(() {});
        }
      },
    );
  }

  _removeImage() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("取消图片"),
            content: const Text("确认取消图片吗？"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("取消")),
              ElevatedButton(
                  onPressed: () {
                    SPUtil.setString("img_file_path", "");
                    _imgFile = null; // 需要将该成员设置会null，setState才有效果
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                  child: const Text("确认")),
            ],
          );
        });
  }
}
