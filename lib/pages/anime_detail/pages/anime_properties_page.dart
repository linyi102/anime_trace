import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/pages/anime_detail/controllers/anime_controller.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../../../components/dialog/dialog_select_play_status.dart';

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
      appBar: AppBar(
          title: const Text("动漫信息",
              style: TextStyle(fontWeight: FontWeight.w600))),
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
            String animeName = anime.animeName;
            _showDialogAboutEdit(context, title: "编辑名称", property: animeName,
                confirm: (newName) {
              if (newName.isEmpty) {
                showToast("动漫名不允许为空");
                return;
              }
              Log.info("更新名称：$newName");

              animeController.anime.animeName = newName;
              animeController.updateAnimeInfo();

              SqliteUtil.updateAnimeNameByAnimeId(anime.animeId, newName);
            });
          }),
          _buildPropRow(context, title: "别名", content: anime.nameAnother,
              onPressed: () {
            String nameAnother = anime.nameAnother;
            _showDialogAboutEdit(context, title: "编辑别名", property: nameAnother,
                confirm: (newNameAnother) {
              Log.info("更新别名：$newNameAnother");

              animeController.anime.nameAnother = newNameAnother;
              animeController.updateAnimeInfo();

              SqliteUtil.updateAnimeNameAnotherByAnimeId(
                  anime.animeId, newNameAnother);
            });
          }),
          _buildPropRow(context, title: "地区", content: anime.area),
          _buildPropRow(context, title: "类别", content: anime.category),
          _buildPropRow(context, title: "首播时间", content: anime.premiereTime),
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
          _buildPropRow(context, title: "动漫链接", content: anime.animeUrl),
          _buildPropRow(context, title: "封面链接", content: anime.animeCoverUrl),
          _buildPropRow(
            context,
            title: "简介",
            content: anime.animeDesc,
            onPressed: () {
              String animeDesc = anime.animeDesc;
              _showDialogAboutEdit(context, title: "编辑简介", property: animeDesc,
                  confirm: (newDesc) {
                Log.info("更新简介：$newDesc");

                animeController.anime.animeDesc = newDesc;
                animeController.updateAnimeInfo();

                SqliteUtil.updateAnimeDescByAnimeId(anime.animeId, newDesc);
              });
            },
          ),
          const ListTile()
        ],
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
          title: GestureDetector(
            onTap: onPressed,
            child: Row(
              children: [
                Text("$title "),
                if (onPressed != null)
                  const Icon(EvaIcons.editOutline, size: 18)
              ],
            ),
          ),
          subtitle: GestureDetector(
            onTap: onPressed,
            child: _buildSelectedOrUrlText(
              context,
              content,
              // 如果可以点击，则文字不可选，保证能够触发点击事件
              select: onPressed == null ? true : false,
            ),
          ),
        )
      ],
    );
  }

  _showDialogAboutEdit(BuildContext context,
      {required String title,
      required dynamic property,
      Widget? dialogContent,
      required Function(String) confirm}) {
    showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(title),
            // 如果传了dialogContent，就显示传入的，否则默认显示该文本输入框
            content: dialogContent ??
                TextField(
                    controller: textController..text = property,
                    minLines: 1,
                    maxLines: 10,
                    maxLength: 999),
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
                      ElevatedButton(
                          onPressed: () {
                            confirm(textController.text);
                            Navigator.pop(dialogContext); // 退出编辑对话框
                          },
                          child: const Text("确认"))
                    ],
                  )
                ],
              )
            ],
          );
        });
  }

  // 文本http开头提供访问功能，其他则是复制
  _buildSelectedOrUrlText(BuildContext context, String text,
      {bool select = true}) {
    if (text.startsWith("http")) {
      return GestureDetector(
        onTap: () => LaunchUrlUtil.launch(context: context, uriStr: text),
        child: Text(text, style: const TextStyle(color: Colors.blue)),
      );
    } else if (select) {
      // 下滑时有时候没有反应，因为会触发到选中文本
      return SelectableText(text.isEmpty ? "无" : text);
    } else {
      return Text(text.isEmpty ? "无" : text);
    }
  }
}
