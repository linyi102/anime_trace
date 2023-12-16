import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_image.dart';

import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/pages/settings/image_path_setting.dart';
import 'package:flutter_test_future/utils/file_util.dart';
import 'package:flutter_test_future/utils/platform.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/widgets/multi_platform.dart';
import 'package:flutter_test_future/widgets/stack_appbar.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_test_future/utils/log.dart';

// 图片浏览器
class ImageViewerPage extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const ImageViewerPage({
    Key? key,
    required this.imagePaths,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  List<String> get imagePaths => widget.imagePaths;
  int get imagesCount => widget.imagePaths.length;
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
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
    scrollController.dispose();
  }

  _getImageLocalPaths() {
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
    if (currentIndex >= imagePaths.length) currentIndex = imagePaths.length - 1;
    if (currentIndex < 0) currentIndex = 0;

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
          child: imagePaths.isEmpty
              ? const Scaffold(
                  backgroundColor: Colors.black,
                  body: Stack(
                    children: [
                      StackAppBar(),
                      Align(
                        alignment: Alignment.center,
                        child:
                            Text('没有图片', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                )
              : Scaffold(
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
                            offstage:
                                imagePaths.length == 1 ? true : fullScreen,
                            child: MultiPlatform(
                                mobile: SizedBox(
                                  height: 100,
                                  width: MediaQuery.of(context).size.width,
                                  child: _buildScrollAxis(),
                                ),
                                desktop: Container(
                                  height: 100,
                                  padding: const EdgeInsets.all(6),
                                  width:
                                      MediaQuery.of(context).size.width * 2 / 3,
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
                          currentIndex < widget.imagePaths.length - 1)
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
    return StackAppBar(
      title: imagePaths.length > 1 ? _buildImageProgressText() : '',
      actions: _buildActions(),
    );
  }

  _buildImageProgressText() {
    return Text("${currentIndex + 1}/${imagePaths.length}",
        style: const TextStyle(color: Colors.white, fontSize: 18));
  }

  _buildPhotoViewGallery() {
    return PhotoViewGallery.builder(
      // 如果开启旋转，手机双指放大时很容易歪
      // enableRotation: true,
      itemCount: imagePaths.length,
      pageController: pageController,
      onPageChanged: (index) {
        setState(() {
          currentIndex = index;
        });
        _scrollToCurrentImage();
      },
      // backgroundDecoration: BoxDecoration(
      //   color: fullScreen
      //       ? Colors.black
      //       : Theme.of(context).scaffoldBackgroundColor,
      // ),
      // 设置加载时的背景色，避免加载时突然白屏
      loadingBuilder: (buildContext, imageChunkEvent) =>
          Container(color: Colors.black),
      builder: (context, index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: FileImage(File(imagePaths[index])),
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
                    Log.info("修改了图片目录，重新获取本地图片");
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
    File file = File(imagePaths[currentIndex]);

    return [
      IconButton(
          onPressed: () async {
            _showDialogDeleteFile(file);
          },
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
          )),
      IconButton(
          onPressed: () async {
            _showDialogAboutImageAttributes(file);
          },
          icon: const Icon(
            Icons.info_outline_rounded,
            color: Colors.white,
          )),
    ];
  }

  Future<dynamic> _showDialogDeleteFile(File file) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确定删除吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await file.delete();
                  imagePaths.removeAt(currentIndex);
                  if (imagePaths.isEmpty) {
                    Navigator.pop(context);
                  }
                  setState(() {});
                } on Exception catch (_) {
                  ToastUtil.showText('删除失败');
                }
              },
              child: Text(
                '删除',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )),
        ],
      ),
    );
  }

  _showDialogAboutImageAttributes(File file) {
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
                      title: const Text("完全路径"),
                      subtitle: SelectableText(
                        imagePaths[currentIndex],
                      )),
                  if (file.existsSync())
                    ListTile(
                        contentPadding: EdgeInsetsDirectional.zero,
                        title: const Text("图片大小"),
                        subtitle: Text(
                          FileUtil.getReadableFileSize(file.lengthSync()),
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
        itemCount: imagePaths.length,
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
                              ? Theme.of(context).primaryColor
                              : Colors.transparent)),
                  // 切割圆角图片
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 100,
                      width: 140,
                      child: CommonImage(imagePaths[index]),
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
