import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animetrace/components/empty_data_hint.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/dao/anime_dao.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/pages/anime_detail/controllers/anime_controller.dart';
import 'package:animetrace/pages/settings/image_path_setting.dart';
import 'package:animetrace/utils/climb/climb_anime_util.dart';
import 'package:animetrace/utils/extensions/color.dart';
import 'package:animetrace/utils/image_util.dart';
import 'package:get/get.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:photo_view/photo_view.dart';

import '../../../global.dart';

/// 动漫详细页点击封面，进入该页面
/// 提供缩放、修改封面、重新根据动漫网址获取封面的功能
class AnimeCoverDetail extends StatelessWidget {
  const AnimeCoverDetail({required this.animeController, Key? key})
      : super(key: key);
  final AnimeController animeController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: Stack(
        children: [
          Center(
              child: GetBuilder<AnimeController>(
                  id: animeController.coverId,
                  init: animeController,
                  builder: (controller) {
                    return _buildAnimeCover(
                        animeController.anime.animeCoverUrl, context);
                  })),
          // Positioned(
          //   // bottom: 0,
          //   top: 0,
          //   child: SizedBox(
          //     height: MediaQuery.of(context).padding.top + kToolbarHeight,
          //     width: MediaQuery.of(context).size.width,
          //     child: _buildAppbar(context, enableOpacity: true),
          //   ),
          // ),
        ],
      ),
    );
  }

  AppBar _buildAppbar(BuildContext context, {bool enableOpacity = false}) {
    return AppBar(
      backgroundColor: enableOpacity
          // 获取当前context对应的Element的的scaffold背景，并调整不透明度
          ? Theme.of(context).scaffoldBackgroundColor.withOpacityFactor(0.6)
          : null,
      actions: [
        _buildInfoButton(context),
        _buildRefreshButton(context),
        IconButton(
            onPressed: () => _showDialogAboutHowToEditCoverUrl(context),
            icon: const Icon(Icons.edit))
      ],
    );
  }

  _buildRefreshButton(BuildContext context) {
    return IconButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text("更新封面"),
                  content: const Text("该操作会通过动漫网址更新封面，如果有自定义封面，会进行覆盖，确定更新吗？"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text("取消")),
                    TextButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          Anime anime = animeController.anime;
                          if (anime.animeUrl.isEmpty) {
                            ToastUtil.showText("无来源，无法获取封面");
                            return;
                          }
                          ToastUtil.showText("正在获取封面");

                          anime =
                              await ClimbAnimeUtil.climbAnimeInfoByUrl(anime);
                          // 爬取后，只更新动漫封面
                          AnimeDao.updateAnimeCoverUrl(
                                  anime.animeId, anime.animeCoverUrl)
                              .then((value) {
                            // 更新控制器中的动漫封面
                            animeController.updateCoverUrl(anime.animeCoverUrl);

                            // 获取失败后会提示连接超时，所以这里不显示
                            // ToastUtil.showText("更新封面成功！");
                          });
                        },
                        child: const Text("确定")),
                  ],
                );
              });
        },
        icon: const Icon(Icons.refresh));
  }

  _buildInfoButton(BuildContext context) {
    return IconButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text("属性"),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsetsDirectional.zero,
                          dense: true,
                          title: const Text("链接"),
                          subtitle: SelectableText(
                              animeController.anime.animeCoverUrl),
                        )
                      ],
                    ),
                  ),
                );
              });
        },
        icon: const Icon(Icons.info_outline));
  }

  _buildAnimeCover(String coverUrl, BuildContext context) {
    if (coverUrl.isEmpty) {
      return emptyDataHint(msg: "没有封面~");
    }

    ImageProvider imageProvider;
    // 网络封面
    if (coverUrl.startsWith("http")) {
      imageProvider = NetworkImage(
        coverUrl,
        headers: coverUrl.contains("douban")
            ? Global.getHeadersToGetDoubanPic()
            : null,
      );
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
      loadingBuilder: (_, __) => const LoadingWidget(center: true),
      errorBuilder: (context, url, error) => _buildErrorInfo(context),
      imageProvider: imageProvider,
      backgroundDecoration:
          BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
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
                    return const AlertDialog(
                      title: Text("失效可能的原因"),
                      content: SingleChildScrollView(
                        child: Column(
                          children: [
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
          return SimpleDialog(
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text("从本地图库中选择"),
                onTap: () {
                  if (Platform.isIOS || Platform.isOhos) {
                    ToastUtil.showText('暂不支持选择本地图片');
                    return;
                  }
                  _selectCoverFromLocal(
                      context, howToEditCoverUrlDialogContext);
                },
              ),
              ListTile(
                  dense: true,
                  style: ListTileStyle.drawer,
                  leading: const SizedBox.shrink(),
                  title: const Text("前往设置本地封面目录"),
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
                  _showDialogAboutEditCoverUrl(howToEditCoverUrlDialogContext);
                },
              ),
            ],
          );
        });
  }

  _showDialogAboutEditCoverUrl(BuildContext howToEditCoverUrlDialogContext) {
    var textController = TextEditingController();

    showDialog(
        context: howToEditCoverUrlDialogContext,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text("链接"),
            content: TextField(
              controller: textController
                ..text = animeController.anime.animeCoverUrl,
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
                      TextButton(
                          onPressed: () {
                            animeController.updateCoverUrl(textController.text);

                            AnimeDao.updateAnimeCoverUrl(
                                animeController.anime.animeId,
                                animeController.anime.animeCoverUrl);
                            Navigator.pop(dialogContext); // 退出编辑对话框
                            Navigator.pop(
                                howToEditCoverUrlDialogContext); // 退出选择对话框
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

  _selectCoverFromLocal(context, howToEditCoverUrlDialogContext) async {
    if (!ImageUtil.hasCoverImageRootDirPath()) {
      ToastUtil.showText("请先设置封面根目录");
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
      AnimeDao.updateAnimeCoverUrl(
          animeController.anime.animeId, relativeImagePath);
      animeController.updateCoverUrl(relativeImagePath);
      // 退出选择
      Navigator.pop(howToEditCoverUrlDialogContext);
    } else {
      throw ("未适配平台：${Platform.operatingSystem}");
    }
  }
}
