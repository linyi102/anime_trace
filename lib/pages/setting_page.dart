import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/settings/about_version.dart';
import 'package:flutter_test_future/scaffolds/settings/anime_display_setting.dart';
import 'package:flutter_test_future/scaffolds/settings/backup_restore.dart';
import 'package:flutter_test_future/scaffolds/settings/note_setting.dart';
import 'package:flutter_test_future/scaffolds/settings/tag_manage.dart';
import 'package:flutter_test_future/utils/color_theme_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorThemeUtil.getScaffoldBackgroundColor(),
      appBar: AppBar(
        backgroundColor: ColorThemeUtil.getScaffoldBackgroundColor(),
        title: Text(
          "更多",
          style: TextStyle(
            color: ColorThemeUtil.getAppBarTitleColor(),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: !_loadOk
            ? Container(
                key: UniqueKey(),
              )
            : ListView(
                children: [
                  _showImg(),
                  _showImgButton(),
                  ListTile(
                    textColor: ColorThemeUtil.getListTileColor(),
                    leading: const Icon(
                      Icons.settings_backup_restore_outlined,
                      color: Colors.blue,
                    ),
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
                    textColor: ColorThemeUtil.getListTileColor(),
                    leading: const Icon(
                      Icons.new_label_outlined,
                      color: Colors.blue,
                    ),
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
                    textColor: ColorThemeUtil.getListTileColor(),
                    leading: const Icon(
                      Icons.book_outlined,
                      color: Colors.blue,
                    ),
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
                    textColor: ColorThemeUtil.getListTileColor(),
                    leading: const Icon(
                      Icons.note_alt_outlined,
                      color: Colors.blue,
                    ),
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
                    textColor: ColorThemeUtil.getListTileColor(),
                    leading: const Icon(Icons.dark_mode_outlined,
                        color: Colors.blue),
                    title: const Text("夜间模式"),
                    trailing: SPUtil.getBool("enableDark")
                        ? const Icon(Icons.toggle_on,
                            color: Colors.blue, size: 32)
                        : const Icon(Icons.toggle_off, size: 32),
                    onTap: () {
                      SPUtil.setBool(
                          "enableDark", !SPUtil.getBool("enableDark"));
                      setState(() {});
                    },
                  ),
                  ListTile(
                    textColor: ColorThemeUtil.getListTileColor(),
                    leading: const Icon(
                      Icons.error_outline,
                      color: Colors.blue,
                    ),
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
                  )
                ],
              ),
      ),
    );
  }

  _showImg() {
    return _imgFile == null
        ? Container()
        : SizedBox(
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
          );
  }

  _showImgButton() {
    return ListTile(
      textColor: ColorThemeUtil.getListTileColor(),
      leading: const Icon(
        // Icons.image_outlined,
        // Icons.wallpaper_outlined,
        Icons.perm_media_outlined,
        color: Colors.blue,
      ),
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
      onLongPress: () {
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
      },
    );
  }
}
