import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animetrace/components/common_image.dart';

import 'package:animetrace/global.dart';
import 'package:animetrace/pages/settings/about_version.dart';
import 'package:animetrace/pages/settings/backup_restore/home.dart';
import 'package:animetrace/pages/settings/image_path_setting.dart';
import 'package:animetrace/pages/settings/checklist_manage_page.dart';
import 'package:animetrace/pages/settings/label/home.dart';
import 'package:animetrace/pages/settings/series/manage/view.dart';
import 'package:animetrace/pages/settings/theme_page.dart';
import 'package:animetrace/routes/get_route.dart';
import 'package:animetrace/utils/sp_util.dart';
import 'package:animetrace/values/values.dart';
import 'package:animetrace/widgets/common_divider.dart';
import 'package:animetrace/widgets/responsive.dart';
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
  bool get enableSplitView => false;

  Widget? settingDetailView;

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
      body: Responsive(
        mobile: _buildSettingListView(),
        tablet: _buildSettingListView(),
        desktop: enableSplitView ? _buildSplitView() : _buildSettingListView(),
      ),
    );
  }

  _buildSplitView() {
    return Row(
      children: [
        Expanded(child: _buildSettingListView()),
        _buildSettingDetailView(),
      ],
    );
  }

  ListView _buildSettingListView() {
    return ListView(
      children: [
        _buildBanner(),
        if (enableDivider) const CommonDivider(),
        Card(child: _buildFunctionGroup()),
        if (enableDivider) const CommonDivider(),
        Card(child: _buildSettingGroup()),
        if (enableDivider) const CommonDivider(),
        Card(child: _buildOtherGroup()),
      ],
    );
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
            _enterDetail(const AboutVersion());
          },
        ),
        if (!Global.isRelease)
          ListTile(
            iconColor: Theme.of(context).primaryColor,
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text("测试页面"),
            onTap: () {
              _enterDetail(const TestPage());
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
            MingCuteIcons.mgc_settings_1_line,
          ),
          title: const Text("常规设置"),
          onTap: () {
            _enterDetail(const GeneralSettingPage());
          },
        ),
        ListTile(
          iconColor: Theme.of(context).primaryColor,
          leading: const Icon(
            // Icons.photo_size_select_actual_outlined,
            // Icons.image_outlined,
            MingCuteIcons.mgc_pic_2_line,
            // MingCuteIcons.mgc_photo_album_line,
          ),
          title: const Text("图片设置"),
          onTap: () {
            _enterDetail(const ImagePathSetting());
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
            _enterDetail(const ThemePage());
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
          leading: const Icon(Icons.settings_backup_restore_rounded),
          title: const Text("备份还原"),
          onTap: () {
            _enterDetail(const BackupAndRestorePage());
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
            _enterDetail(const ChecklistManagePage());
          },
        ),
        ListTile(
          iconColor: Theme.of(context).primaryColor,
          leading: const Icon(
            // Icons.label_outline,
            MingCuteIcons.mgc_tag_line,
          ),
          title: const Text("标签管理"),
          onTap: () {
            _enterDetail(const LabelManagePage());
          },
        ),
        ListTile(
          iconColor: Theme.of(context).primaryColor,
          leading: const Icon(MingCuteIcons.mgc_book_3_line),
          // leading: SvgAssetIcon(
          //   assetPath: Assets.iconsCollections24Regular,
          //   color: Theme.of(context).primaryColor,
          // ),
          title: const Text("系列管理"),
          onTap: () {
            _enterDetail(const SeriesManagePage());
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

    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight / 4,
      child: Card(
        child: InkWell(
          onTap: () => _showDialogBanner(),
          child: _selectedImageTypeIdx == 0
              ? Center(
                  child: Image.asset(
                  "assets/images/logo-round.png",
                  width: screenHeight / 8,
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
              if (!Platform.isIOS && !Platform.isOhos)
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

  _enterDetail(Widget detailView) {
    if (Responsive.isDesktop(context) && enableSplitView) {
      setState(() {
        settingDetailView = detailView;
      });
    } else {
      RouteUtil.materialTo(context, detailView);
    }
  }

  _buildSettingDetailView() {
    if (settingDetailView == null) return const SizedBox();
    return Expanded(child: settingDetailView!);
  }
}
