import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/components/img_widget.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:photo_view/photo_view.dart';

import '../settings/image_path_setting.dart';

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

  // 在图片浏览器中进入图片设置页面，可能会更改目录，为true时，用于图片浏览页的上级页面重新加载图片。
  // 暂时没有办法，因为上一级是NoteImgItem，是无状态组件，不能更新
  bool dirChangedWrapper = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _getImageLocalPaths();
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
      scrollToCurrentImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 如果处于全屏，则退出全屏模式，否则退出该页面
        if (fullScreen) {
          _exitFullScreen();
          return false;
        } else {
          Navigator.of(context).pop(dirChangedWrapper);
          return true;
        }
      },
      child: Scaffold(
        appBar: fullScreen
            ? null
            : AppBar(
                // 隐藏自带的返回按钮
                automaticallyImplyLeading: false,
                // 返回按钮
                leading: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop(dirChangedWrapper);
                  },
                  icon: const Icon(Icons.arrow_back_outlined),
                ),
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
                          ListTile(
                              title: const Text("相对路径"),
                              subtitle: SelectableText(widget
                                  .relativeLocalImages[currentIndex].path)),
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
          imageProvider: FileImage(File(imageLocalPaths[currentIndex])),
          // 错误时显示提示
          errorBuilder: (buildContext, object, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("无法正常显示图片"),
                const Text("请检查目录下是否存在该图片"),
                TextButton(
                    onPressed: () {
                      Navigator.of(context)
                          .push(FadeRoute(
                              builder: (context) => const ImagePathSetting()))
                          .then((dirChanged) {
                        if (dirChanged) {
                          debugPrint("修改了图片目录，重新获取本地图片");
                          _getImageLocalPaths();
                          setState(() {});
                          dirChangedWrapper = true; // 用于图片浏览器的上级页面更新状态
                        }
                      });
                    },
                    child: const Text("点此处设置目录"))
              ],
            );
          },
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
                                  ? ThemeUtil.getPrimaryColor()
                                  : Colors.transparent)),
                      // 切割圆角图片
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          // 从设置界面返回来，如果改变了目录，则这里应该重新渲染
                          // key发生变化，所以就会重新渲染该组件
                          key: Key("$index:$dirChangedWrapper"),
                          height: 100,
                          width: 140,
                          child: buildImgWidget(
                              // 传入相对路径
                              url: widget.relativeLocalImages[index].path,
                              showErrorDialog: false,
                              isNoteImg: true),
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
