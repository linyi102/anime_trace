import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/controllers/anime_controller.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path/path.dart';

import '../../components/dialog/dialog_select_play_status.dart';
import '../../models/anime.dart';
import '../../utils/theme_util.dart';

class AnimePropertiesPage extends StatelessWidget {
  AnimeController animeController = Get.find();
  var textController = TextEditingController();

  AnimePropertiesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 不能使用ListView，因为外部是SliverChildListDelegate
    return Obx(() => Padding(
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPropRow(context,
                  title: "名称",
                  text: animeController.anime.value.animeName, onTap: () {
                String animeName = animeController.anime.value.animeName;
                _showDialogAboutEdit(context,
                    title: "编辑名称", property: animeName, confirm: (newName) {
                  if (newName.isEmpty) {
                    showToast("动漫名不允许为空");
                    return;
                  }
                  debugPrint("更新名称：$newName");
                  animeController.updateAnimeName(newName);
                  SqliteUtil.updateAnimeNameByAnimeId(
                      animeController.anime.value.animeId, newName);
                });
              }),
              _buildPropRow(context,
                  title: "别名",
                  text: animeController.anime.value.nameAnother, onTap: () {
                String nameAnother = animeController.anime.value.nameAnother;
                _showDialogAboutEdit(context,
                    title: "编辑别名",
                    property: nameAnother, confirm: (newNameAnother) {
                  debugPrint("更新别名：$newNameAnother");
                  animeController.updateAnimeNameAnother(newNameAnother);
                  SqliteUtil.updateAnimeNameAnotherByAnimeId(
                      animeController.anime.value.animeId, newNameAnother);
                });
              }),
              _buildPropRow(context,
                  title: "状态",
                  text: animeController.anime.value.getPlayStatus(), onTap: () {
                showDialogSelectPlayStatus(context, animeController);
              }),
              _buildPropRow(context,
                  title: "描述",
                  text: animeController.anime.value.animeDesc, onTap: () {
                String animeDesc = animeController.anime.value.animeDesc;
                _showDialogAboutEdit(context,
                    title: "编辑简介", property: animeDesc, confirm: (newDesc) {
                  debugPrint("更新简介：$newDesc");
                  animeController.updateAnimeDesc(newDesc);
                  SqliteUtil.updateAnimeDescByAnimeId(
                      animeController.anime.value.animeId, newDesc);
                });
              }),
              const ListTile()
            ],
          ),
        ));
  }

  /// 点击后会弹出编辑文本框的动漫属性行
  _buildPropRow(BuildContext context,
      {required String title,
      required String text,
      required void Function()? onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
      child: Text.rich(
          TextSpan(children: [
            TextSpan(text: "$title："),
            WidgetSpan(
                child: GestureDetector(
              onTap: onTap,
              child: Text(
                text.isNotEmpty ? text : "什么都没有~",
                style: TextStyle(color: ThemeUtil.getCommentColor()),
              ),
            ))
          ]),
          textScaleFactor: 0.9),
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

  _buildContent(BuildContext context, String content) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      child: _buildUrlText(context, content),
    );
  }

  // 以http开头就提供访问功能
  _buildUrlText(BuildContext context, String url) {
    FontWeight fontWeight = FontWeight.normal;
    double fontSize = 14.0;

    if (url.startsWith("http")) {
      return GestureDetector(
        onTap: () async {
          LaunchUrlUtil.launch(context: context, uriStr: url);
        },
        child: Text(url,
            style: TextStyle(
                color: ThemeUtil.getPrimaryIconColor(),
                fontWeight: fontWeight,
                fontSize: fontSize)),
      );
    } else {
      return Text(url.isEmpty ? "什么都没有~" : url,
          style: TextStyle(
              color: ThemeUtil.getCommentColor(),
              fontWeight: fontWeight,
              fontSize: fontSize));
    }
  }
}
