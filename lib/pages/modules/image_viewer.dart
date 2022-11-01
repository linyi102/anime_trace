import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';
import 'package:flutter_test_future/components/error_image_builder.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:gesture_zoom_box/gesture_zoom_box.dart';

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
  bool showScrollAxis = true;

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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("${currentIndex + 1}/${imageLocalPaths.length}"),
        actions: _buildActions(context),
      ),
      body: Container(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            _buildImage(),
            if (showScrollAxis) _buildScrollAxis(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          showScrollAxis = !showScrollAxis;
          setState(() {});
          if (showScrollAxis) {
            Future.delayed(const Duration(milliseconds: 200)).then((value) {
              scrollToCurrentImage();
            });
          }
        },
        icon: Icon(showScrollAxis ? Icons.fullscreen : Icons.fullscreen_exit),
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

  void _swipeFunction(DragEndDetails dragEndDetails) {
    // 切换到下一张
    if (dragEndDetails.primaryVelocity! < 0 &&
        currentIndex + 1 < imageLocalPaths.length) {
      currentIndex++;
      setState(() {});
    }
    // 切换到上一张
    if (dragEndDetails.primaryVelocity! > 0 && currentIndex - 1 >= 0) {
      currentIndex--;
      setState(() {});
    }
    // 移动图片轴
    scrollToCurrentImage();
  }

  _buildImage() {
    return Expanded(
      flex: 3,
      child: GestureDetector(
        onHorizontalDragEnd: _swipeFunction,
        child: Container(
          // color: Colors.redAccent,
          color: Colors.transparent, // 必须要添加颜色，不然手势检测不到Container，只能检测到图片
          // 左右滑动图片
          // 缩放手势和切换图片冲突
          child: GestureZoomBox(
              maxScale: 5.0,
              doubleTapScale: 2.0,
              duration: const Duration(milliseconds: 200),
              child: Image.file(File(imageLocalPaths[currentIndex]),
                  fit: BoxFit.fitWidth)),
          // child: Image.file(
          //   File(imageLocalPaths[currentIndex]),
          //   fit: BoxFit.fitWidth,
          //   errorBuilder: errorImageBuilder(
          //       widget.relativeLocalImages[currentIndex].path),
          // ),
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
                      margin: const EdgeInsets.only(left: 8, right: 8),
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
    scrollController.animateTo(180.0 * (currentIndex - 1),
        duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }
}
