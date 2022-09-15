import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:oktoast/oktoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/theme_util.dart';

class AnimePropertiesPage extends StatefulWidget {
  final Anime anime;

  const AnimePropertiesPage(this.anime, {Key? key}) : super(key: key);

  @override
  State<AnimePropertiesPage> createState() => _AnimePropertiesPageState();
}

class _AnimePropertiesPageState extends State<AnimePropertiesPage> {
  late Anime anime;

  @override
  void initState() {
    super.initState();
    anime = widget.anime;
  }

  var textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        ListTile(
          title: const Text("网址"),
          trailing: IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text("网址编辑"),
                        content: TextField(
                          controller: textController..text = anime.animeUrl,
                          maxLength: 999,
                        ),
                        actions: [
                          Row(
                            children: [
                              Row(
                                children: [
                                  TextButton(
                                      onPressed: () {
                                        textController.clear();
                                      },
                                      child: const Text("清空")),
                                  TextButton(
                                      onPressed: () async {
                                        ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
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
                                      onPressed: () {
                                        Navigator.pop(dialogContext);
                                      },
                                      child: const Text("取消")),
                                  ElevatedButton(
                                      onPressed: () {
                                        Anime oldAnime = anime.copy();
                                        setState(() {
                                          anime.animeUrl = textController.text;
                                        });
                                        // 方法内部当某个为空字符串时会把旧的属性添加到上去，所以不能保存空字符串
                                        SqliteUtil.updateAnime(oldAnime, anime);
                                        Navigator.pop(dialogContext);
                                      },
                                      child: const Text("确认"))
                                ],
                              )
                            ],
                          )
                        ],
                      );
                    });
              },
              icon: const Icon(Icons.edit)),
        ),
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          child: TextButton(
              onPressed: () async {
                Uri uri;
                if (anime.animeUrl.isNotEmpty) {
                  uri = Uri.parse(anime.animeUrl);
                  if (!await launchUrl(uri,
                      mode: LaunchMode.externalApplication)) {
                    throw "Could not launch $uri";
                  }
                } else {
                  showToast("网址为空，请先迁移动漫");
                }
              },
              child: Text(anime.animeUrl)),
          // Text(anime.animeUrl, style: TextStyle(color: Colors.blue, fontSize: 14))
        ),
        const ListTile(
          title: Text("简介"),
        ),
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          child: Text(anime.animeDesc,
              style:
                  TextStyle(color: ThemeUtil.getCommentColor(), fontSize: 14)),
        )
      ],
    );
  }
}
