import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:photo_view/photo_view.dart';

// 点击笔记图片，进入浏览页面
class ImageViewer extends StatefulWidget {
  final List<RelativeLocalImage> relativeLocalImages;
  final int initialIndex;

  const ImageViewer({
    Key? key,
    required this.relativeLocalImages,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  List<String> imageLocalPaths = [];
  int imagesCount = 0;
  int currentIndex = 0;
  bool fullScreen = false; // 全屏显示图片，此时因此顶部栏和滚动轴

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    for (var relativeLocalImage in widget.relativeLocalImages) {
      imageLocalPaths
          .add(ImageUtil.getAbsoluteNoteImagePath(relativeLocalImage.path));
    }
    imagesCount = imageLocalPaths.length;

    // 首次进入可能选的是后面的图片，也需要移动
    Future.delayed(const Duration(milliseconds: 200)).then((value) {
      scrollToCurrentImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 如果处于全屏，则退出全屏模式，否则退出该页面
        if (fullScreen) {
          fullScreen = false;
          setState(() {});
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        appBar: fullScreen
            ? null
            : AppBar(
                centerTitle: true,
                title: Text("${currentIndex + 1}/${imageLocalPaths.length}"),
                actions: _buildActions(context),
              ),
        body: Container(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              _buildImage(),
              if (!fullScreen) _buildScrollAxis(),
            ],
          ),
        ),
      ),
    );
  }

  _exitFullScreen() {
    fullScreen = false;
    setState(() {});
    // 延时，确保滚动轴出来后再移动
    Future.delayed(const Duration(milliseconds: 200)).then((value) {
      scrollToCurrentImage(); // 退出全屏后移动图片轴```到当前图片
    });
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          fullScreen = true;
          setState(() {});
        },
        icon: const Icon(Icons.fullscreen),
        tooltip: "全屏显示",
      ),
      IconButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Text("图片属性"),
                    content: SingleChildScrollView(
                      child: Column(
                        children: [
                          ListTile(
                              title: const Text("完全路径"),
                              subtitle: SelectableText(
                                  imageLocalPaths[currentIndex])),
                        ],
                      ),
                    ),
                  );
                });
          },
          icon: const Icon(Icons.error_outline))
    ];
  }

  void _swipeFunction(ScaleEndDetails scaleEndDetails) {
    int newIdx = currentIndex;
    debugPrint(scaleEndDetails.toString());
    // 往右滑，大于0，要切换到上一张
    double dx = scaleEndDetails.velocity.pixelsPerSecond.dx;
    // 切换到下一张
    if (dx < 0) {
      newIdx++;
    }
    // 切换到上一张
    else if (dx > 0) {
      newIdx--;
    }
    if (0 <= newIdx && newIdx < imageLocalPaths.length) {
      currentIndex = newIdx;
      setState(() {});
      // 移动图片轴
      scrollToCurrentImage();
    }
  }

  _buildImage() {
    return Expanded(
      flex: 3,
      child: Container(
        // color: Colors.redAccent,
        color: Colors.transparent, // 必须要添加颜色，不然手势检测不到Container，只能检测到图片
        child: PhotoView(
          backgroundDecoration:
              BoxDecoration(color: ThemeUtil.getScaffoldBackgroundColor()),
          // 切换图片
          onScaleEnd:
              (buildContext, scaleEndDetails, photoViewControllerValue) {
            // 放大图片后移动也会导致切换图片，所以没有使用
            // _swipeFunction(scaleEndDetails);
          },
          // 全屏状态下单击，松开后退出全屏
          onTapUp: fullScreen
              ? (buildContext, details, photoViewControllerValue) =>
                  _exitFullScreen()
              : null,
          imageProvider: FileImage(
            File(imageLocalPaths[currentIndex]),
          ),
        ),
      ),
    );
  }

  ScrollController scrollController = ScrollController();

  _buildScrollAxis() {
    return Expanded(
        flex: 1,
        child: ListView.builder(
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
                      scrollToCurrentImage();
                      setState(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              width: 4,
                              color: index == currentIndex
                                  ? ThemeUtil.getThemePrimaryColor()
                                  : Colors.transparent)),
                      // 切割圆角图片
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(imageLocalPaths[index]),
                          fit: BoxFit.cover,
                          height: 100,
                          width: 140,
                          errorBuilder: (context, error, stackTrace) {
                            return Container();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }));
  }

  void scrollToCurrentImage() {
    if (currentIndex == 0) return; // 如果访问的是第一个图片，不需要移动共用轴
    scrollController.animateTo(150.0 * (currentIndex - 1),
        duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }
}
