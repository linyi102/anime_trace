import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/scaffolds/anime_detail/controller/anime_controller.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../classes/anime.dart';
import '../../utils/theme_util.dart';

class AnimePropertiesPage extends StatelessWidget {
  AnimeController animeController = Get.find();
  var textController = TextEditingController();

  AnimePropertiesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 不能使用ListView，因为外部是SliverChildListDelegate
    return Obx(() => Column(
          children: [
            _buildAnimeName(context),
            _buildAnotherName(context),
            _buildAnimeUrl(context),
            _buildAnimeDesc(context),
            const SizedBox(height: 80)
          ],
        ));
  }

  Column _buildAnimeName(BuildContext context) {
    String animeName = animeController.anime.value.animeName;
    return Column(
      children: [
        ListTile(
          title: const Text("名称"),
          trailing: IconButton(
              onPressed: () {
                _showDialogAboutEdit(context,
                    title: "编辑别名", property: animeName, confirm: (newName) {
                  if (newName.isEmpty) {
                    showToast("动漫名不允许为空");
                    return;
                  }
                  debugPrint("更新别名：$newName");
                  animeController.updateAnimeName(newName);
                  SqliteUtil.updateAnimeNameByAnimeId(
                      animeController.anime.value.animeId, newName);
                });
              },
              icon: const Icon(Icons.edit)),
        ),
        _buildContent(animeName)
      ],
    );
  }

  Column _buildAnotherName(BuildContext context) {
    String nameAnother = animeController.anime.value.nameAnother;
    return Column(
      children: [
        ListTile(
          title: const Text("别名"),
          trailing: IconButton(
              onPressed: () {
                _showDialogAboutEdit(context,
                    title: "编辑别名",
                    property: nameAnother, confirm: (newNameAnother) {
                  debugPrint("更新别名：$newNameAnother");
                  animeController.updateAnimeNameAnother(newNameAnother);
                  SqliteUtil.updateAnimeNameAnotherByAnimeId(
                      animeController.anime.value.animeId, newNameAnother);
                });
              },
              icon: const Icon(Icons.edit)),
        ),
        _buildContent(nameAnother)
      ],
    );
  }

  Column _buildAnimeUrl(BuildContext context) {
    String animeUrl = animeController.anime.value.animeUrl;
    return Column(
      children: [
        ListTile(
          title: const Text("网址"),
          trailing: IconButton(
              onPressed: () {
                _showDialogAboutEdit(context, title: "编辑网址", property: animeUrl,
                    confirm: (newUrl) {
                  animeController.updateAnimeUrl(textController.text);
                  SqliteUtil.updateAnimeUrl(animeController.anime.value.animeId,
                      animeController.anime.value.animeUrl);
                },
                    dialogContent: TextField(
                        controller: textController..text = animeUrl,
                        minLines: 1,
                        maxLines: 10,
                        maxLength: 999,
                        decoration: const InputDecoration(
                          helperText: "修改后可能导致无法更新动漫",
                          helperStyle: TextStyle(color: Colors.orangeAccent),
                          counterStyle: TextStyle(color: Colors.grey),
                        )));
              },
              icon: const Icon(Icons.edit)),
        ),
        _buildContent(animeUrl)
      ],
    );
  }

  Column _buildAnimeDesc(BuildContext context) {
    Anime anime = animeController.anime.value;
    return Column(
      children: [
        ListTile(
            title: const Text("简介"),
            trailing: IconButton(
                onPressed: () {
                  _showDialogAboutEdit(context,
                      title: "编辑简介",
                      property: anime.animeDesc, confirm: (newDesc) {
                    debugPrint("更新简介：$newDesc");
                    animeController.updateAnimeDesc(newDesc);
                    SqliteUtil.updateAnimeDescByAnimeId(
                        animeController.anime.value.animeId, newDesc);
                  });
                },
                icon: const Icon(Icons.edit))),
        _buildContent(anime.animeDesc)
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

  _buildContent(String content) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      child: _buildUrlText(content),
    );
  }

  // 以http开头就提供访问功能
  _buildUrlText(String url) {
    FontWeight fontWeight = FontWeight.normal;
    double fontSize = 14.0;

    if (url.startsWith("http")) {
      return MaterialButton(
        // TextButton无法取消填充，所以使用MaterialButton
        padding: const EdgeInsets.all(0),
        onPressed: () async {
          LaunchUrlUtil.launch(url);
        },
        child: Text(url,
            style: TextStyle(
                color: Colors.blue,
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
