import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/pages/settings/about_version.dart';
import 'package:flutter_test_future/pages/settings/anime_display_setting.dart';
import 'package:flutter_test_future/pages/settings/backup_restore.dart';
import 'package:flutter_test_future/pages/settings/image_path_setting.dart';
import 'package:flutter_test_future/pages/settings/tag_manage.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:get/get.dart';

import '../settings/test.dart';

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
            title: const Text("更多",
                style: TextStyle(fontWeight: FontWeight.w600))),
        body: _buildBody());
  }

  _buildBody() {
    if (!_loadOk) {
      return Container(
        key: UniqueKey(),
      );
    }
    // 监听切换主题后的primaryColor(leadingIconColor)
    return Obx(() => ListView(
          children: [
            // _showImg(),
            // _showImgButton(),
            ListTile(
              iconColor: ThemeUtil.getPrimaryIconColor(),
              leading: const Icon(Icons.settings_backup_restore_outlined),
              title: const Text("备份还原"),
              onTap: () {
                Navigator.of(context).push(
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
              iconColor: ThemeUtil.getPrimaryIconColor(),
              leading: const Icon(Icons.checklist_rounded),
              title: const Text("清单管理"),
              onTap: () {
                Navigator.of(context).push(
                  FadeRoute(
                    builder: (context) {
                      return const TagManage();
                    },
                  ),
                );
              },
            ),
            ListTile(
              iconColor: ThemeUtil.getPrimaryIconColor(),
              leading: const Icon(Icons.book_outlined),
              title: const Text("动漫界面"),
              onTap: () {
                Navigator.of(context).push(
                  FadeRoute(
                    builder: (context) {
                      return const AnimesDisplaySetting();
                    },
                  ),
                );
              },
            ),
            ListTile(
              iconColor: ThemeUtil.getPrimaryIconColor(),
              leading: const Icon(Icons.image_outlined),
              title: const Text("图片设置"),
              onTap: () {
                Navigator.of(context).push(
                  FadeRoute(
                    builder: (context) {
                      return const ImagePathSetting();
                    },
                  ),
                );
              },
            ),
            ListTile(
              iconColor: ThemeUtil.getPrimaryIconColor(),
              leading: const Icon(Icons.color_lens_outlined),
              title: const Text("主题样式"),
              onTap: () {
                showDialog(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        content: SingleChildScrollView(
                          child: Column(
                            children: _buildColorAtlasList(dialogContext),
                          ),
                        ),
                      );
                    });
              },
            ),
            ListTile(
              iconColor: ThemeUtil.getPrimaryIconColor(),
              leading: const Icon(Icons.error_outline),
              title: const Text("关于版本"),
              onTap: () {
                Navigator.of(context).push(
                  FadeRoute(
                    builder: (context) {
                      return const AboutVersion();
                    },
                  ),
                );
              },
            ),
            if (!const bool.fromEnvironment("dart.vm.product"))
              ListTile(
                iconColor: ThemeUtil.getPrimaryIconColor(),
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text("测试页面"),
                onTap: () {
                  Navigator.of(context).push(
                    FadeRoute(
                      builder: (context) {
                        return const TestPage();
                      },
                    ),
                  );
                },
              )
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
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                // 圆角
                clipBehavior: Clip.antiAlias,
                // 设置抗锯齿，实现圆角背景
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
      iconColor: ThemeUtil.getPrimaryIconColor(),
      // leading: Icon(FontAwesome.picture),
      leading: const Icon(
          // Icons.image_outlined,
          // Icons.wallpaper_outlined,
          Icons.flag_outlined),
      title: const Text("顶部图片"),
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom, allowedExtensions: ["jpg", "png", "gif"]);
        if (result != null) {
          PlatformFile image = result.files.single;
          String path = image.path as String;
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

  _buildColorAtlasList(dialogContext) {
    List<Widget> dayList = [], nightList = [];
    for (var themeColor in ThemeUtil.themeColors) {
      debugPrint("themeColor=$themeColor");
      if (themeColor.isDarkMode) {
        nightList.add(_buildColorAtlasItem(themeColor, dialogContext));
      } else {
        dayList.add(_buildColorAtlasItem(themeColor, dialogContext));
      }
    }

    List<Widget> list = [];
    list.add(const ListTile(dense: true, title: Text("白天模式")));
    list.addAll(dayList);
    list.add(const ListTile(dense: true, title: Text("夜间模式")));
    list.addAll(nightList);

    return list;
  }

  _buildColorAtlasItem(ThemeColor themeColor, dialogContext) {
    return Obx(() => ListTile(
          trailing: themeController.themeColor.value == themeColor
              ? const Icon(Icons.check)
              : null,
          leading: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: themeColor.representativeColor,
                // border: Border.all(width: 2, color: Colors.red.shade200),
              )),
          title: Text(themeColor.name),
          onTap: () {
            themeController.changeTheme(themeColor.key);
            Navigator.of(dialogContext).pop();
          },
        ));
  }
}
