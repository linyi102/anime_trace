import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/components/common_image.dart';

import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/pages/settings/about_version.dart';
import 'package:flutter_test_future/pages/settings/backup_restore.dart';
import 'package:flutter_test_future/pages/settings/image_path_setting.dart';
import 'package:flutter_test_future/pages/settings/checklist_manage_page.dart';
import 'package:flutter_test_future/pages/settings/image_wall/note_image_wall.dart';
import 'package:flutter_test_future/pages/settings/label_manage_page.dart';
import 'package:flutter_test_future/pages/settings/series/manage/view.dart';
import 'package:flutter_test_future/pages/settings/theme_page.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:flutter_test_future/widgets/common_divider.dart';
import 'package:flutter_test_future/widgets/svg_asset_icon.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import 'general_setting.dart';
import 'test_page.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  // banner
  String _localImageFilePath = SPUtil.getString(bannerFileImagePath);
  String _networkImageUrl = SPUtil.getString(bannerNetworkImageUrl);
  final String _defaultImageUrl = "";
  late int _selectedImageTypeIdx; // 记录选择的哪种图片
  bool get enableDivider => false;

  @override
  void initState() {
    super.initState();

    _selectedImageTypeIdx =
        SPUtil.getInt(bannerSelectedImageTypeIdx, defaultValue: 0);
    if (_selectedImageTypeIdx >= 3) {
      _selectedImageTypeIdx = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ListView(
      children: [
        _buildBanner(),
        if (enableDivider) const CommonDivider(),
        Card(child: _buildFunctionGroup()),
        if (enableDivider) const CommonDivider(),
        Card(child: _buildSettingGroup()),
        if (enableDivider) const CommonDivider(),
        Card(child: _buildOtherGroup()),
      ],
    ));
  }

  Column _buildOtherGroup() {
    return Column(
      children: [
        ListTile(
          iconColor: Theme.of(context).primaryColor,
          leading: const Icon(
            // Icons.info_outlined,
            MingCuteIcons.mgc_information_line,
          ),
          title: const Text("关于版本"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return const AboutVersion();
                },
              ),
            );
          },
        ),
        if (!Global.isRelease)
          ListTile(
            iconColor: Theme.of(context).primaryColor,
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text("测试页面"),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return const TestPage();
                  },
                ),
              );
            },
          )
      ],
    );
  }

  Column _buildSettingGroup() {
    return Column(
      children: [
        ListTile(
          iconColor: Theme.of(context).primaryColor,
          leading: const Icon(
            // Icons.settings,
            MingCuteIcons.mgc_settings_3_line,
          ),
          title: const Text("常规设置"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return const GeneralSettingPage();
                },
              ),
            );
          },
        ),
        ListTile(
          iconColor: Theme.of(context).primaryColor,
          leading: const Icon(
            // Icons.photo_size_select_actual_outlined,
            // Icons.image_outlined,
            // MingCuteIcons.mgc_pic_2_line,
            MingCuteIcons.mgc_photo_album_line,
          ),
          title: const Text("图片设置"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return const ImagePathSetting();
                },
              ),
            );
          },
        ),
        ListTile(
          iconColor: Theme.of(context).primaryColor,
          leading: const Icon(
            // Icons.color_lens_outlined,
            MingCuteIcons.mgc_palette_line,
          ),
          title: const Text("外观设置"),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemePage(),
                ));
          },
        ),
      ],
    );
  }

  Column _buildFunctionGroup() {
    return Column(
      children: [
        ListTile(
          iconColor: Theme.of(context).primaryColor,
          leading: const Icon(Icons.settings_backup_restore_outlined),
          title: const Text("备份还原"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return const BackupAndRestorePage();
                },
              ),
            );
          },
        ),
        ListTile(
          iconColor: Theme.of(context).primaryColor,
          leading: const Icon(
            Icons.checklist_rounded,
            // MingCuteIcons.mgc_check_line,
          ),
          title: const Text("清单管理"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return const ChecklistManagePage();
                },
              ),
            );
          },
        ),
        ListTile(
          iconColor: Theme.of(context).primaryColor,
          leading: const Icon(
            // Icons.label_outline,
            MingCuteIcons.mgc_tag_2_line,
          ),
          title: const Text("标签管理"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return const LabelManagePage();
                },
              ),
            );
          },
        ),
        ListTile(
          leading: SvgAssetIcon(
            assetPath: Assets.iconsCollections24Regular,
            color: Theme.of(context).primaryColor,
          ),
          title: const Text("系列管理"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return const SeriesManagePage();
                },
              ),
            );
          },
        ),
        ListTile(
          iconColor: Theme.of(context).primaryColor,
          leading: const Icon(Icons.panorama_horizontal_rounded),
          title: const Text("照片墙"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return const NoteImageWallPage();
                },
              ),
            );
          },
        ),
      ],
    );
  }

  _buildBanner() {
    String url;
    if (_selectedImageTypeIdx == 0) {
      url = _defaultImageUrl;
    } else if (_selectedImageTypeIdx == 1) {
      url = _localImageFilePath;
    } else {
      url = _networkImageUrl;
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height / 4,
      child: Card(
        child: InkWell(
          onTap: () => _showDialogBanner(),
          child: _selectedImageTypeIdx == 0
              ? Center(
                  child: Image.asset(
                  "assets/images/logo.png",
                  width: MediaQuery.of(context).size.height / 8,
                ))
              : CommonImage(url, reduceMemCache: false),
        ),
      ),
    );
  }

  _showDialogBanner() {
    return showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (BuildContext context, setState) {
          return SimpleDialog(
            children: [
              _buildImageTypeOption(
                  title: "默认图片", imageTypeIdx: 0, setDialogState: setState),
              _buildImageTypeOption(
                title: "本地图片",
                imageTypeIdx: 1,
                setDialogState: setState,
                trailing: TextButton(
                    onPressed: () => _handleProvideLocalImage(),
                    child: const Text("指定")),
              ),
              _buildImageTypeOption(
                title: "网络图片",
                imageTypeIdx: 2,
                setDialogState: setState,
                trailing: TextButton(
                    onPressed: () => _handleProvideNetworkImage(),
                    child: const Text("指定")),
              )
            ],
          );
        },
      ),
    );
  }

  _buildImageTypeOption({
    required String title,
    required int imageTypeIdx,
    Widget? trailing,
    required void Function(void Function()) setDialogState,
  }) {
    return ListTile(
      onTap: () {
        // 重绘对话框
        setDialogState(() {
          _selectedImageTypeIdx = imageTypeIdx;
          SPUtil.setInt(bannerSelectedImageTypeIdx, imageTypeIdx);
        });

        // 重绘更多页
        setState(() {});
      },
      title: Text(title),
      leading: _selectedImageTypeIdx == imageTypeIdx
          ? Icon(Icons.radio_button_checked,
              color: Theme.of(context).primaryColor)
          : const Icon(Icons.radio_button_off),
      trailing: trailing,
    );
  }

  _handleProvideLocalImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ["jpg", "png", "gif"]);
    if (result != null) {
      PlatformFile image = result.files.single;
      String path = image.path as String;
      SPUtil.setString(bannerFileImagePath, path);
      // 重绘更多页
      setState(() {
        _localImageFilePath = path;
      });
    }
  }

  _handleProvideNetworkImage() {
    var textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("图片链接"),
        content: TextField(
          controller: textController..text = _networkImageUrl,
          minLines: 1,
          maxLines: 5,
          maxLength: 999,
        ),
        actions: [
          Row(
            children: [
              Row(
                children: [
                  TextButton(
                      onPressed: () => textController.clear(),
                      child: const Text("清空")),
                  TextButton(
                      onPressed: () async {
                        ClipboardData? data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        if (data != null) {
                          textController.text = data.text ?? "";
                        }
                      },
                      child: const Text("粘贴")),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text("取消")),
                  TextButton(
                      onPressed: () {
                        SPUtil.setString(
                            bannerNetworkImageUrl, textController.text);
                        // 退出输入框
                        Navigator.pop(dialogContext);
                        // 重绘更多页
                        setState(() {
                          _networkImageUrl = textController.text;
                        });
                      },
                      child: const Text("确定"))
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
