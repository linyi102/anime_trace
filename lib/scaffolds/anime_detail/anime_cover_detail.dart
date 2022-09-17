import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/scaffolds/anime_detail/controller/anime_controller.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:gesture_zoom_box/gesture_zoom_box.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

import '../../classes/anime.dart';
import '../../fade_route.dart';
import '../../utils/climb/climb_anime_util.dart';
import '../../utils/image_util.dart';
import '../../utils/sqlite_util.dart';
import '../settings/image_path_setting.dart';

/// 动漫详细页点击封面，进入该页面
/// 提供缩放、修改封面、重新根据动漫网址获取封面的功能
class AnimeCoverDetail extends StatelessWidget {
  AnimeCoverDetail({Key? key}) : super(key: key);
  final AnimeController animeController = Get.find();
  var textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text("封面更新"),
                        content: const Text(
                            "该操作会通过动漫网址更新封面，\n如果有自定义封面，会进行覆盖，\n确定更新吗？"),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                              },
                              child: const Text("取消")),
                          ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(dialogContext);
                                showToast("正在获取封面...");

                                Anime anime = animeController.anime.value;
                                anime =
                                    await ClimbAnimeUtil.climbAnimeInfoByUrl(
                                        anime);
                                // 爬取后，只更新动漫封面
                                SqliteUtil.updateAnimeCoverUrl(
                                        anime.animeId, anime.animeCoverUrl)
                                    .then((value) {
                                  // 更新控制器中的动漫封面
                                  animeController
                                      .updateAnimeCoverUrl(anime.animeCoverUrl);

                                  showToast("更新封面成功！");
                                });
                              },
                              child: const Text("确定")),
                        ],
                      );
                    });
              },
              icon: Icon(Icons.refresh)),
          IconButton(
              onPressed: () => _showDialogAboutHowToEditCoverUrl(context),
              icon: const Icon(Icons.edit))
        ],
      ),
      body: Center(
        child: GestureZoomBox(
          maxScale: 5.0,
          doubleTapScale: 2.0,
          duration: const Duration(milliseconds: 200),
          // obx监听封面修改
          child: Obx(() =>
              _buildAnimeCover(animeController.anime.value.animeCoverUrl)),
        ),
      ),
    );
  }

  _buildAnimeCover(String coverUrl) {
    if (coverUrl.isEmpty) {
      return emptyDataHint("没有封面~");
    }

    // 网络封面
    if (coverUrl.startsWith("http")) {
      return CachedNetworkImage(
        imageUrl: coverUrl,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => const Placeholder(),
      );
    }

    // 本地封面
    return Image.file(
      File(ImageUtil.getAbsoluteCoverImagePath(coverUrl)),
      fit: BoxFit.cover,
    );
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
}