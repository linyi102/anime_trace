import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/components/common_image.dart';

import 'package:animetrace/global.dart';
import 'package:animetrace/models/relative_local_image.dart';
import 'package:animetrace/pages/settings/image_path_setting.dart';
import 'package:animetrace/utils/common_util.dart';
import 'package:animetrace/utils/file_util.dart';
import 'package:animetrace/utils/image_util.dart';
import 'package:animetrace/utils/platform.dart';
import 'package:animetrace/utils/sp_util.dart';
import 'package:animetrace/widgets/bottom_sheet.dart';
import 'package:animetrace/widgets/multi_platform.dart';
import 'package:animetrace/widgets/setting_title.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:animetrace/utils/log.dart';

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
      SPUtil.getBool(fullScreenKey, defaultValue: false); // 默认不开启全屏，全屏时隐藏预览轴

  late PageController pageController;
  ScrollController scrollController = ScrollController();

  bool get showSwitchImageButton => false;

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
        child: Listener(
          onPointerSignal: (pointerSignal) {
            if (PlatformUtil.isDesktop && pointerSignal is PointerScrollEvent) {
              if (pointerSignal.scrollDelta.dy > 0) {
                _animatedToNextImage();
              } else {
                _animatedToPreviousImage();
              }
            }
          },
          child: Scaffold(
            body: Stack(
              children: [
                _buildPhotoViewGallery(),
                // 都叠放在图片上面，否则无法显示
                if (!fullScreen) _buildStackAppBar(context),
                // 没有全屏时显示预览图片
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Offstage(
                      offstage: fullScreen,
                      child: MultiPlatform(
                          mobile: SizedBox(
                            height: 100,
                            width: MediaQuery.of(context).size.width,
                            child: _buildScrollAxis(),
                          ),
                          desktop: Container(
                            height: 100,
                            padding: const EdgeInsets.all(6),
                            width: MediaQuery.of(context).size.width * 2 / 3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.black54,
                            ),
                            child: _buildScrollAxis(),
                          )),
                    ),
                  ),
                ),
                if (showSwitchImageButton &&
                    PlatformUtil.isDesktop &&
                    currentIndex > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _HoverButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () {
                        _animatedToPreviousImage();
                      },
                    ),
                  ),
                if (showSwitchImageButton &&
                    PlatformUtil.isDesktop &&
                    currentIndex < widget.relativeLocalImages.length - 1)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _HoverButton(
                      icon: Icons.arrow_forward_rounded,
                      onTap: () {
                        _animatedToNextImage();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ));
  }

  Future<void> _animatedToPreviousImage() {
    return pageController.previousPage(
        duration: const Duration(milliseconds: 600), curve: Curves.easeOutCirc);
  }

  Future<void> _animatedToNextImage() {
    return pageController.nextPage(
        duration: const Duration(milliseconds: 600), curve: Curves.easeOutCirc);
  }

  _buildStackAppBar(BuildContext context) {
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
          icon: const Icon(
            MingCuteIcons.mgc_close_line,
            color: Colors.white,
            size: 22,
          ),
        ),
        centerTitle: true,
        title: imageLocalPaths.length > 1 ? _buildImageProgressText() : null,
        actions: _buildActions(),
      ),
    );
  }

  _buildImageProgressText() {
    return Text("${currentIndex + 1}/${imageLocalPaths.length}",
        style: const TextStyle(color: Colors.white, fontSize: 18));
  }

  _buildPhotoViewGallery() {
    return PhotoViewGallery.builder(
      // 如果开启旋转，手机双指放大时很容易歪
      // enableRotation: true,
      itemCount: imageLocalPaths.length,
      pageController: pageController,
      onPageChanged: (index) {
        setState(() {
          currentIndex = index;
        });
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
            _turnFullScreen();
          },
        );
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
            const Text("无法正常显示图片", style: TextStyle(color: Colors.white)),
            const Text("请检查目录下是否存在该图片", style: TextStyle(color: Colors.white)),
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (context) => const ImagePathSetting()))
                    .then((dirChanged) {
                  if (dirChanged) {
                    AppLog.info("修改了图片目录，重新获取本地图片");
                    _getImageLocalPaths();
                    setState(() {});
                    // 用于图片浏览器的上级页面更新状态
                    Global.modifiedImgRootPath = true;
                  }
                });
              },
              child: const Text("点此处设置目录"),
            ),
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

  _turnFullScreen() {
    if (fullScreen) {
      _exitFullScreen();
    } else {
      _enterFullScreen();
    }
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

  List<Widget> _buildActions() {
    return [
      IconButton(
          onPressed: () {
            _showDialogAboutImageAttributes();
          },
          icon: const Icon(
            Icons.info_outline,
            color: Colors.white,
          ))
    ];
  }

  _showDialogAboutImageAttributes() {
    File file = File(ImageUtil.getAbsoluteNoteImagePath(
        widget.relativeLocalImages[currentIndex].path));

    return showCommonModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (dialogContext) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SettingTitle(title: '信息'),
                ListTile(
                  title: const Text("完全路径"),
                  subtitle: Text(imageLocalPaths[currentIndex]),
                  onTap: () =>
                      CommonUtil.copyContent(imageLocalPaths[currentIndex]),
                ),
                ListTile(
                  title: const Text("相对路径"),
                  subtitle: Text(widget.relativeLocalImages[currentIndex].path),
                  onTap: () => CommonUtil.copyContent(
                      widget.relativeLocalImages[currentIndex].path),
                ),
                if (file.existsSync())
                  ListTile(
                      title: const Text("图片大小"),
                      subtitle: Text(
                          FileUtil.getReadableFileSize(file.lengthSync()))),
              ],
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
                              ? Theme.of(context).colorScheme.primary
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

    scrollController.animateTo(150.0 * (currentIndex - 1),
        duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }
}

class _HoverButton extends StatelessWidget {
  const _HoverButton({
    required this.icon,
    this.onTap,
  });
  final IconData icon;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 30,
          width: 30,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Colors.black87),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
