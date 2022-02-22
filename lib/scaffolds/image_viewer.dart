import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/relative_local_image.dart';
import 'package:flutter_test_future/components/error_image_builder.dart';
import 'package:flutter_test_future/utils/image_util.dart';

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

  @override
  void initState() {
    currentIndex = widget.initialIndex;
    for (var relativeLocalImage in widget.relativeLocalImages) {
      imageLocalPaths
          .add(ImageUtil.getAbsoluteImagePath(relativeLocalImage.path));
    }
    imagesCount = imageLocalPaths.length;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MaterialButton(
        padding: const EdgeInsets.all(0),
        onPressed: () {
          Navigator.pop(context);
        },
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              Center(
                child: Image.file(
                  File(imageLocalPaths[currentIndex]),
                  fit: BoxFit.cover,
                  errorBuilder: errorImageBuilder(
                      widget.relativeLocalImages[currentIndex].path),
                ),
              ),
              _dislpayCloseButton(),
              imagesCount == 1 ? Container() : _displayBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _displayBottomButton() {
    return Container(
        alignment: Alignment.bottomCenter,
        child: Card(
          elevation: 4,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15))), // 圆角
          clipBehavior: Clip.antiAlias, // 设置抗锯齿，实现圆角背景
          color: Colors.black,
          margin: const EdgeInsets.fromLTRB(50, 20, 50, 20),
          child: Row(
            children: [
              Expanded(
                child: IconButton(
                  onPressed: () {
                    if (currentIndex - 1 < 0) {
                      return;
                    }
                    currentIndex--;
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.chevron_left_outlined,
                    color: Colors.white70,
                  ),
                ),
              ),
              Text(
                imagesCount == 1 ? "" : "${currentIndex + 1}/$imagesCount",
                style: const TextStyle(color: Colors.white70),
              ),
              Expanded(
                child: IconButton(
                  onPressed: () {
                    if (currentIndex + 1 >= imagesCount) {
                      return;
                    }
                    currentIndex++;
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.chevron_right_outlined,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ));
  }

// 不能在AppBar的actions中添加，否则图片不是特别居中
  Widget _dislpayCloseButton() {
    return Positioned(
      top: 10,
      right: 10,
      child: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.close,
            color: Colors.white70,
          )),
    );
  }
}
