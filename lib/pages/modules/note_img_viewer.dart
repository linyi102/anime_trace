import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_image.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';
import 'package:flutter_test_future/pages/settings/image_path_setting.dart';
import 'package:flutter_test_future/utils/file_util.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_test_future/utils/log.dart';

// 点击笔记图片，进入浏览页面
class ImageViewerPage extends StatefulWidget {
  final List<RelativeLocalImage> relativeLocalImages;
  final int initialIndex;

  const ImageViewerPage({
    Key? key,
    required this.relativeLocalImages,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  List<String> imageLocalPaths = [];
  int imagesCount = 0;
  int currentIndex = 0;

  static const fullScreenKey = "fullScreenInNoteImageViewer";
  bool fullScreen =
      SPUtil.getBool(fullScreenKey, defaultValue: false); // 全屏显示图片，此时因此顶部栏和滚动轴

  late PageController pageController;
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: widget.initialIndex);
    _getImageLocalPaths();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
    scrollController.dispose();
  }

  _getImageLocalPaths() {
    imageLocalPaths.clear();
    for (var relativeLocalImage in widget.relativeLocalImages) {
      imageLocalPaths
          .add(ImageUtil.getAbsoluteNoteImagePath(relativeLocalImage.path));
    }
    imagesCount = imageLocalPaths.length;
    // 首次进入可能选的是后面的图片，也需要移动
    Future.delayed(const Duration(milliseconds: 200)).then((value) {
      _scrollToCurrentImage();
    });
  }

  _pop() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          _pop();
          return true;
        },
        child: Scaffold(
          body: Stack(
            children: [
              _buildPhotoViewGallery(),
              // 都叠放在图片上面，否则无法显示
              _buildStackAppBar(context),
              if (!fullScreen)
                Positioned(
                  bottom: 10,
                  child: SizedBox(
                    height: 100,
                    width: MediaQuery.of(context).size.width,
                    child: _buildScrollAxis(),
                  ),
                )
            ],
          ),
        ));
  }

  SizedBox _buildStackAppBar(BuildContext context) {
    return SizedBox(
      // 高度为手机状态栏高度+AppBar高度
      height: kToolbarHeight + MediaQuery.of(context).padding.top,
      width: MediaQuery.of(context).size.width,
      child: AppBar(
        backgroundColor: Colors.transparent,
        // 隐藏自带的返回按钮
        automaticallyImplyLeading: false,
        // 返回按钮
        leading: IconButton(
          onPressed: () => _pop(),
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.white),
        ),
        centerTitle: true,
        title: imageLocalPaths.length > 1 ? _buildImageProgressText() : null,
        actions: _buildActions(context),
      ),
    );
  }

  _buildImageProgressText() {
    return Text("${currentIndex + 1}/${imageLocalPaths.length}",
        style: const TextStyle(color: Colors.white, fontSize: 18));
  }

  _buildPhotoViewGallery() {
    return PhotoViewGallery.builder(
      enableRotation: true,
      itemCount: imageLocalPaths.length,
      pageController: pageController,
      onPageChanged: (index) {
        currentIndex = index;
        setState(() {});
        _scrollToCurrentImage();
      },
      // 设置加载时的背景色，避免加载时突然白屏
      loadingBuilder: (buildContext, imageChunkEvent) =>
          Container(color: Colors.black),
      builder: (context, index) {
        return PhotoViewGalleryPageOptions(
            imageProvider: FileImage(File(imageLocalPaths[index])),
            errorBuilder: (buildContext, object, stackTrace) {
              return _buildErrorImage(context);
            },
            onTapUp: (_, __, ___) {
              if (fullScreen) {
                _exitFullScreen();
              } else {
                _enterFullScreen();
              }
            });
      },
    );
  }

  _buildErrorImage(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "无法正常显示图片",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "请检查目录下是否存在该图片",
              style: TextStyle(color: Colors.white),
            ),
            TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (context) => const ImagePathSetting()))
                      .then((dirChanged) {
                    if (dirChanged) {
                      Log.info("修改了图片目录，重新获取本地图片");
                      _getImageLocalPaths();
                      setState(() {});
                      // 用于图片浏览器的上级页面更新状态
                      Global.modifiedNoteImgRootPath = true;
                    }
                  });
                },
                child: const Text("点此处设置目录")),
            // 当构建错误组件时，全屏后无法单击退出全屏，所以这里提供文字按钮
            if (fullScreen)
              TextButton(
                  onPressed: () => _exitFullScreen(), child: const Text("退出全屏"))
          ],
        ),
      ),
    );
  }

  _enterFullScreen() {
    setState(() {
      fullScreen = true;
    });
    SPUtil.setBool(fullScreenKey, fullScreen);
  }

  _exitFullScreen() {
    setState(() {
      fullScreen = false;
      SPUtil.setBool(fullScreenKey, fullScreen);
    });
    // 延时，确保滚动轴出来后再移动
    Future.delayed(const Duration(milliseconds: 200)).then((value) {
      _scrollToCurrentImage(); // 退出全屏后移动图片轴到当前图片
    });
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      IconButton(
          tooltip: "图片信息",
          onPressed: () {
            _showDialogAboutImageAttributes(context);
          },
          icon: const Icon(Icons.info_outlined, color: Colors.white))
    ];
  }

  _showDialogAboutImageAttributes(BuildContext context) {
    File file = File(ImageUtil.getAbsoluteNoteImagePath(
        widget.relativeLocalImages[currentIndex].path));
    if (!file.existsSync()) {
      return;
    }

    return showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text("图片信息"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                      contentPadding: EdgeInsetsDirectional.zero,
                      dense: true,
                      title: const Text("完全路径"),
                      subtitle: SelectableText(
                        imageLocalPaths[currentIndex],
                        textScaleFactor: 0.9,
                      )),
                  ListTile(
                      contentPadding: EdgeInsetsDirectional.zero,
                      dense: true,
                      title: const Text("相对路径"),
                      subtitle: SelectableText(
                        widget.relativeLocalImages[currentIndex].path,
                        textScaleFactor: 0.9,
                      )),
                  ListTile(
                      contentPadding: EdgeInsetsDirectional.zero,
                      dense: true,
                      title: const Text("图片大小"),
                      subtitle: Text(
                        FileUtil.getReadableFileSize(file.lengthSync()),
                        textScaleFactor: 0.9,
                      )),
                ],
              ),
            ),
          );
        });
  }

  _buildScrollAxis() {
    return ListView.builder(
        controller: scrollController, // 记得加上控制器
        itemCount: imageLocalPaths.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // 点击共用轴中的图片
              GestureDetector(
                onTap: () {
                  if (currentIndex == index) {
                    return;
                  }
                  // 先设置当前下标，然后在移动
                  currentIndex = index;

                  // 页号变化时，onPageChanged里会调用_scrollToCurrentImage，因此这里不需要再调用
                  pageController.jumpToPage(index);
                },
                child: Container(
                  margin: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          width: 4,
                          color: index == currentIndex
                              ? ThemeUtil.getPrimaryColor()
                              : Colors.transparent)),
                  // 切割圆角图片
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 100,
                      width: 140,
                      child: CommonImage(ImageUtil.getAbsoluteNoteImagePath(
                          widget.relativeLocalImages[index].path)),
                    ),
                  ),
                ),
              ),
            ],
          );
        });
  }

  void _scrollToCurrentImage() {
    if (currentIndex == 0) return; // 如果访问的是第一个图片，不需要移动共用轴

    if (!fullScreen) {
      scrollController.animateTo(150.0 * (currentIndex - 1),
          duration: const Duration(milliseconds: 200), curve: Curves.linear);
    }
  }
}
