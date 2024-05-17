import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_play_status.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/enum/anime_area.dart';
import 'package:flutter_test_future/models/enum/anime_category.dart';
import 'package:flutter_test_future/pages/anime_detail/controllers/anime_controller.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/common/category_intro_page.dart';
import 'package:flutter_test_future/routes/get_route.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/widgets/picker/date_time_picker.dart';
import 'package:get/get.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/utils/log.dart';

class AnimePropertiesPage extends StatelessWidget {
  AnimePropertiesPage({required this.animeController, Key? key})
      : super(key: key);
  final AnimeController animeController;
  final textController = TextEditingController();

  Anime get anime => animeController.anime;

  @override
  Widget build(BuildContext context) {
    // 不能使用ListView，因为外部是SliverChildListDelegate
    return Scaffold(
      appBar: AppBar(title: const Text("动漫信息")),
      body: GetBuilder<AnimeController>(
        id: animeController.infoPageId,
        init: animeController,
        builder: (controller) {
          return _buildBody(context);
        },
      ),
    );
  }

  _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPropRow(context, title: "名称", content: anime.animeName,
              onPressed: () {
            _showDialogAboutEdit(context,
                title: "名称", initialValue: anime.animeName, confirm: (newName) {
              if (newName.isEmpty) {
                ToastUtil.showText("动漫名不允许为空");
                return;
              }
              Log.info("更新名称：$newName");

              animeController.anime.animeName = newName;
              animeController.updateAnimeInfo();

              AnimeDao.updateAnimeNameByAnimeId(anime.animeId, newName);
            });
          }),
          _buildPropRow(context, title: "别名", content: anime.nameAnother,
              onPressed: () {
            _showDialogAboutEdit(context,
                title: "别名",
                initialValue: anime.nameAnother, confirm: (newNameAnother) {
              Log.info("更新别名：$newNameAnother");

              animeController.anime.nameAnother = newNameAnother;
              animeController.updateAnimeInfo();

              AnimeDao.updateAnimeNameAnotherByAnimeId(
                  anime.animeId, newNameAnother);
            });
          }),
          _buildPropRow(
            context,
            title: "地区",
            content: anime.area,
            onPressed: () => _showDialogEditArea(context),
          ),
          _buildPropRow(
            context,
            title: "类别",
            content: anime.category,
            onPressed: () => _showDialogEditCategory(context),
          ),
          _buildPropRow(
            context,
            title: "首播时间",
            content: anime.premiereTime,
            onPressed: () => _showDialogEditPremiereTime(context),
          ),
          _buildPropRow(context,
              title: "播放状态",
              content: anime.getPlayStatus().text, onPressed: () {
            showDialogSelectPlayStatus(context, animeController);
          }),
          // _buildPropRow(context, title: "原作者", content: anime.authorOri),
          // _buildPropRow(context, title: "原作名", content: anime.nameOri),
          // _buildPropRow(context, title: "官网", content: anime.officialSite),
          // _buildPropRow(context,
          //     title: "制作公司", content: anime.productionCompany),
          _buildPropRow(
            context,
            title: "动漫链接",
            content: anime.animeUrl,
            onPressed: () {
              _showDialogAboutEdit(context,
                  title: "动漫链接",
                  initialValue: anime.animeUrl,
                  helperText: "修改可能导致下拉刷新失效", confirm: (value) {
                Log.info("更新封面：$value");

                animeController.anime.animeUrl = value;
                animeController.updateAnimeInfo();
                AnimeDao.updateAnimeUrl(anime.animeId, value);
              });
            },
          ),
          _buildPropRow(
            context,
            title: "封面链接",
            content: anime.animeCoverUrl,
            onPressed: () {
              _showDialogAboutEdit(context,
                  title: "封面链接",
                  initialValue: anime.animeCoverUrl, confirm: (value) {
                Log.info("更新封面：$value");

                animeController.anime.animeCoverUrl = value;
                animeController.updateAnimeInfo();
                animeController.updateCoverUrl(value);
                AnimeDao.updateAnimeCoverUrl(anime.animeId, value);
              });
            },
          ),
          _buildPropRow(
            context,
            title: "简介",
            content: anime.animeDesc,
            onPressed: () {
              _showDialogAboutEdit(context,
                  title: "简介",
                  initialValue: anime.animeDesc, confirm: (newDesc) {
                Log.info("更新简介：$newDesc");

                animeController.anime.animeDesc = newDesc;
                animeController.updateAnimeInfo();

                AnimeDao.updateAnimeDescByAnimeId(anime.animeId, newDesc);
              });
            },
          ),
          const ListTile()
        ],
      ),
    );
  }

  _showDialogEditPremiereTime(BuildContext context) async {
    var initialDate = DateTime.tryParse(anime.premiereTime);
    initialDate ??= DateTime.now();
    var selectedDate = await showCommonDateTimePicker(
      context: context,
      initialValue: initialDate,
      maxYear: DateTime.now().year + 10,
      type: PickerDateTimeType.kYMD,
    );
    if (selectedDate == null) return;

    String value = selectedDate.toString().substring(0, 10);
    anime.premiereTime = value;
    animeController.updateAnimeInfo();
    AnimeDao.updatePremiereTime(anime.animeId, value);
  }

  _showDialogEditCategory(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Row(
          children: [
            const Text("类别"),
            const Spacer(),
            IconButton(
                onPressed: () {
                  RouteUtil.materialTo(context, const CategoryIntroPage());
                },
                icon: const Icon(Icons.help_outline))
          ],
        ),
        children: AnimeCategory.values
            .map((e) => e.label)
            .map((e) => RadioListTile(
                  title: Text(e),
                  value: e,
                  groupValue: anime.category,
                  onChanged: (value) {
                    if (value == null) return;

                    Navigator.pop(context);
                    anime.category = value;
                    animeController.updateAnimeInfo();
                    AnimeDao.updateCategory(anime.animeId, value);
                  },
                ))
            .toList(),
      ),
    );
  }

  _showDialogEditArea(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("地区"),
        children: AnimeArea.values
            .map((e) => e.label)
            .map((e) => RadioListTile(
                  title: Text(e),
                  value: e,
                  groupValue: anime.area,
                  onChanged: (value) {
                    if (value == null) return;

                    Navigator.pop(context);
                    anime.area = value;
                    animeController.updateAnimeInfo();
                    AnimeDao.updateArea(anime.animeId, value);
                  },
                ))
            .toList(),
      ),
    );
  }

  /// 点击后会弹出编辑文本框的动漫属性行
  _buildPropRow(
    BuildContext context, {
    required String title,
    required String content,
    void Function()? onPressed,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onPressed,
          title: Row(
            children: [
              Text("$title "),
              // if (onPressed != null)
              //   const Icon(MingCuteIcons.mgc_edit_3_line, size: 14)
            ],
          ),
          subtitle: GestureDetector(
            onTap: onPressed,
            child: Text(content),
          ),
          trailing: content.startsWith("http")
              ? IconButton(
                  onPressed: () {
                    LaunchUrlUtil.launch(context: context, uriStr: content);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 18))
              : null,
        )
      ],
    );
  }

  _showDialogAboutEdit(BuildContext context,
      {required String title,
      required dynamic initialValue,
      Widget? dialogContent,
      String? helperText,
      required Function(String value) confirm}) {
    showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(title),
            // 如果传了dialogContent，就显示传入的，否则默认显示该文本输入框
            content: dialogContent ??
                TextField(
                  controller: textController..text = initialValue,
                  minLines: 1,
                  maxLines: 10,
                  autofocus: true,
                  maxLength: 999,
                  decoration: InputDecoration(helperText: helperText),
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
                  Expanded(child: Container()),
                  Row(
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text("取消")),
                      TextButton(
                          onPressed: () {
                            confirm(textController.text);
                            Navigator.pop(dialogContext); // 退出编辑对话框
                          },
                          child: const Text("确定"))
                    ],
                  )
                ],
              )
            ],
          );
        });
  }
}
