import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/scaffolds/anime_detail/controller/anime_controller.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

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
            _buildAnimeUrl(context),
            _buildAnimeDesc()
          ],
        ));
  }

  // 以http开头就提供访问功能，否则以灰色字体显示
  _buildUrlText(String url) {
    if (url.startsWith("http")) {
      return MaterialButton(
        // TextButton无法取消填充，所以使用MaterialButton
        padding: const EdgeInsets.all(0),
        onPressed: () async {
          Uri uri;
          if (url.isNotEmpty) {
            uri = Uri.parse(url);
            if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
              throw "Could not launch $uri";
            }
          }
        },
        child: Text(url,
            style: const TextStyle(
                color: Colors.blue, fontWeight: FontWeight.normal)),
      );
    } else {
      // 本地封面地址
      return MaterialButton(
        padding: const EdgeInsets.all(0),
        child: Text(url.isEmpty ? "什么都没有~" : url,
            style: TextStyle(
                color: ThemeUtil.getCommentColor(),
                fontWeight: FontWeight.normal)),
        onPressed: () {},
      );
    }
  }



  Column _buildAnimeUrl(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text("网址"),
          trailing: IconButton(
              onPressed: () {
                _showDialogAboutEditAnimeUrl(context);
              },
              icon: const Icon(Icons.edit)),
        ),
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          child: _buildUrlText(animeController.anime.value.animeUrl),
          // Text(anime.animeUrl, style: TextStyle(color: Colors.blue, fontSize: 14))
        ),
      ],
    );
  }



  _showDialogAboutEditAnimeUrl(BuildContext context) {
    showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text("修改网址"),
            content: TextField(
                controller: textController
                  ..text = animeController.anime.value.animeUrl,
                minLines: 1,
                maxLines: 5,
                maxLength: 999,
                decoration: const InputDecoration(
                  helperText: "修改后可能导致无法更新动漫",
                  helperStyle: TextStyle(color: Colors.orangeAccent),
                  counterStyle: TextStyle(color: Colors.grey),
                )),
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
                            animeController.updateAnimeUrl(textController.text);

                            SqliteUtil.updateAnimeUrl(
                                animeController.anime.value.animeId,
                                animeController.anime.value.animeUrl);
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

  Column _buildAnimeDesc() {
    return Column(
      children: [
        const ListTile(
          title: Text("简介"),
        ),
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          child: Text(
              animeController.anime.value.animeDesc.isEmpty
                  ? "什么都没有~"
                  : animeController.anime.value.animeDesc,
              style:
                  TextStyle(color: ThemeUtil.getCommentColor(), fontSize: 14)),
        ),
      ],
    );
  }
}
