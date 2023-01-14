import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/controllers/anime_controller.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_view/photo_view.dart';

import '../../models/anime.dart';
import '../../utils/climb/climb_anime_util.dart';
import '../../utils/image_util.dart';
import '../../utils/sqlite_util.dart';
import '../../utils/theme_util.dart';
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
          _buildInfoButton(context),
          _buildRefreshButton(context),
          IconButton(
              onPressed: () => _showDialogAboutHowToEditCoverUrl(context),
              icon: const Icon(Icons.edit))
        ],
      ),
      body: Center(
        // obx监听封面修改
        child: Obx(() => _buildAnimeCover(
            animeController.anime.value.animeCoverUrl, context)),
      ),
    );
  }

  IconButton _buildRefreshButton(BuildContext context) {
    return IconButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text("封面更新"),
                  content:
                      const Text("该操作会通过动漫网址更新封面，\n如果有自定义封面，会进行覆盖，\n确定更新吗？"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text("取消")),
                    ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          Anime anime = animeController.anime.value;
                          if (anime.animeUrl.isEmpty) {
                            showToast("无来源，无法获取封面");
                            return;
                          }
                          showToast("正在获取封面...");

                          anime =
                              await ClimbAnimeUtil.climbAnimeInfoByUrl(anime);
                          // 爬取后，只更新动漫封面
                          SqliteUtil.updateAnimeCoverUrl(
                                  anime.animeId, anime.animeCoverUrl)
                              .then((value) {
                            // 更新控制器中的动漫封面
                            animeController
                                .updateAnimeCoverUrl(anime.animeCoverUrl);

                            // 获取失败后会提示连接超时，所以这里不显示
                            // showToast("更新封面成功！");
                          });
                        },
                        child: const Text("确定")),
                  ],
                );
              });
        },
        icon: const Icon(Icons.refresh));
  }

  IconButton _buildInfoButton(BuildContext context) {
    return IconButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text("封面信息"),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        Obx(() => ListTile(
                              contentPadding: EdgeInsetsDirectional.zero,
                              dense: true,
                              title: const Text("链接"),
                              subtitle: SelectableText(
                                  animeController.anime.value.animeCoverUrl),
                            ))
                      ],
                    ),
                  ),
                );
              });
        },
        icon: const Icon(Icons.error_outline));
  }

  _buildAnimeCover(String coverUrl, BuildContext context) {
    if (coverUrl.isEmpty) {
      return emptyDataHint("没有封面~");
    }

    ImageProvider imageProvider;
    // 网络封面
    if (coverUrl.startsWith("http")) {
      imageProvider = CachedNetworkImageProvider(coverUrl, errorListener: () {
        Log.error("缓存网络图片错误：$coverUrl");
      });
    } else {
      imageProvider =
          FileImage(File(ImageUtil.getAbsoluteCoverImagePath(coverUrl)));
    }
    // 封面更新后从无(_buildErrorInfo)到有(imageProvider)会报错，而使用return Image(image: imageProvider);则不会
    // 而再次手动修改到错误图片，再刷新封面时就不会了，退出时因为第一次没有图片缓存，所以在获取图片的过程中报错了
    // 为PhotoView设置loadingBuilder: (_, __) => CircularProgressIndicator(),更新图片时不会显示进度圈，只有在进入该页面才会显示
    /**
     * The following _CastError was thrown building ImageWrapper(dirty, state: _ImageWrapperState#1cbfe):
        Null check operator used on a null value

        The relevant error-causing widget was:
        PhotoView PhotoView:file:///D:/MC/code_big/flutter/anime_trace/lib/pages/anime_detail/anime_cover_detail.dart:142:12
     */
    return PhotoView(
      // loadingBuilder: (_, __) => const CircularProgressIndicator(),
      errorBuilder: (context, url, error) => _buildErrorInfo(context),
      imageProvider: imageProvider,
      backgroundDecoration:
          BoxDecoration(color: ThemeUtil.getScaffoldBackgroundColor()),
    );
  }

  Widget _buildErrorInfo(context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("X_X"),
        const Text("无法正常显示图片"),
        IconButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text("失效可能的原因"),
                      content: SingleChildScrollView(
                        child: Column(
                          children: const [
                            ListTile(
                              title: Text("网络图片"),
                              subtitle: Text("1. 链接失效\n2. 网络不可用"),
                            ),
                            ListTile(
                              title: Text("本地图片"),
                              subtitle: Text("1. 该图片不在设置的目录下\n2. 图片重命名了"),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
            },
            icon: const Icon(Icons.help_outline))
      ],
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
                    leading: const Icon(Icons.image),
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
                          MaterialPageRoute(
                            builder: (context) {
                              return const ImagePathSetting();
                            },
                          ),
                        );
                      }),
                  // const SizedBox(height: 20),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.link),
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
        MaterialPageRoute(
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
      // List<PlatformFile> platformFiles = result.files;
      PlatformFile platformFile = result.files.single;
      String absoluteImagePath = platformFile.path ?? "";
      if (absoluteImagePath.isEmpty) return;

      String relativeImagePath =
          ImageUtil.getRelativeCoverImagePath(absoluteImagePath);
      // 获取到封面的相对地址后，添加到数据库，并更新controller中的动漫封面
      SqliteUtil.updateAnimeCoverUrl(
          animeController.anime.value.animeId, relativeImagePath);
      animeController.updateAnimeCoverUrl(relativeImagePath);
      // 退出选择
      Navigator.pop(howToEditCoverUrlDialogContext);
    } else {
      throw ("未适配平台：${Platform.operatingSystem}");
    }
  }
}
