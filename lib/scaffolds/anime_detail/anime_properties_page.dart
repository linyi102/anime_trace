import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/scaffolds/anime_detail/controller/anime_controller.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:fluttericon/linearicons_free_icons.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../../fade_route.dart';
import '../../utils/image_util.dart';
import '../../utils/theme_util.dart';
import '../settings/image_path_setting.dart';

class AnimePropertiesPage extends StatelessWidget {
  AnimeController animeController = Get.find();
  var textController = TextEditingController();

  AnimePropertiesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 不能使用ListView，因为外部是SliverChildListDelegate
    return Obx(() => Column(
          children: [
            _buildCoverUrl(context),
            _buildAnimeUrl(context),
            _buildAnimeDesc()
          ],
        ));
  }

  Column _buildCoverUrl(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text("封面"),
          trailing: IconButton(
              onPressed: () {
                _showDialogAboutHowToEditCoverUrl(context);
              },
              icon: const Icon(Icons.edit)),
        ),
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          child: _buildUrlText(animeController.anime.value.animeCoverUrl),
        )
      ],
    );
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

  _showDialogAboutHowToEditCoverUrl(context) {
    showDialog(
        context: context,
        builder: (howToEditCoverUrlDialogContext) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Entypo.picture),
                    title: const Text("从本地图库中选择"),
                    onTap: () {
                      _selectCoverFromLocal(
                          context, howToEditCoverUrlDialogContext);
                    },
                  ),
                  ListTile(
                      dense: true,
                      style: ListTileStyle.drawer,
                      title: const Text("点击前往设置封面根目录"),
                      onTap: () {
                        Navigator.pop(howToEditCoverUrlDialogContext);
                        Navigator.of(context).push(
                          FadeRoute(
                            builder: (context) {
                              return const ImagePathSetting();
                            },
                          ),
                        );
                      }),
                  // const SizedBox(height: 20),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Entypo.network),
                    title: const Text("提供封面链接"),
                    onTap: () {
                      _showDialogAboutEditCoverUrl(
                          howToEditCoverUrlDialogContext);
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  _selectCoverFromLocal(context, howToEditCoverUrlDialogContext) async {
    if (!ImageUtil.hasCoverImageRootDirPath()) {
      showToast("请先设置封面根目录");
      Navigator.pop(howToEditCoverUrlDialogContext);
      Navigator.of(context).push(
        FadeRoute(
          builder: (context) {
            return const ImagePathSetting();
          },
        ),
      );
      return;
    }

    if (Platform.isWindows || Platform.isAndroid) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'gif'],
        allowMultiple: false,
      );
      if (result == null) return;
      List<PlatformFile> platformFiles = result.files;
      for (var platformFile in platformFiles) {
        String absoluteImagePath = platformFile.path ?? "";
        if (absoluteImagePath.isEmpty) continue;

        String relativeImagePath =
            ImageUtil.getRelativeCoverImagePath(absoluteImagePath);

        // 获取到封面的相对地址后，添加到数据库，并更新controller中的动漫封面
        SqliteUtil.updateAnimeCoverUrl(
            animeController.anime.value.animeId, relativeImagePath);
        animeController.updateAnimeCoverUrl(relativeImagePath);
        // 退出选择
        Navigator.pop(howToEditCoverUrlDialogContext);
      }
    } else {
      throw ("未适配平台：${Platform.operatingSystem}");
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

  _showDialogAboutEditCoverUrl(BuildContext howToEditCoverUrlDialogContext) {
    showDialog(
        context: howToEditCoverUrlDialogContext,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text("封面链接编辑"),
            content: TextField(
              controller: textController
                ..text = animeController.anime.value.animeCoverUrl,
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
                  Expanded(child: Container()),
                  Row(
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text("取消")),
                      ElevatedButton(
                          onPressed: () {
                            animeController
                                .updateAnimeCoverUrl(textController.text);

                            SqliteUtil.updateAnimeCoverUrl(
                                animeController.anime.value.animeId,
                                animeController.anime.value.animeCoverUrl);
                            Navigator.pop(dialogContext); // 退出编辑对话框
                            Navigator.pop(
                                howToEditCoverUrlDialogContext); // 退出选择对话框
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

  _showDialogAboutEditAnimeUrl(BuildContext context) {
    showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text("网址编辑"),
            content: TextField(
              controller: textController
                ..text = animeController.anime.value.animeUrl,
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
