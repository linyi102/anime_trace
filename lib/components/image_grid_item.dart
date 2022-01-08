import 'dart:io';

import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/utils/image_util.dart';

class ImageGridItem extends StatelessWidget {
  final String relativeImagePath; // 单张图片
  final MultiImageProvider? multiImageProvider; // 传入多个图片
  final int initialIndex; // 传入多个图片的起始下标
  const ImageGridItem(
      {this.multiImageProvider,
      required this.relativeImagePath,
      this.initialIndex = 0,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String imageLocalPath = ImageUtil.getAbsoluteImagePath(relativeImagePath);

    // debugPrint("relativeImageLocalPath: $relativeImageLocalPath");
    // debugPrint("imageLocalPath: $imageLocalPath");

    final imageProvider = Image.file(
      File(imageLocalPath),
    ).image;

    return MaterialButton(
      padding: const EdgeInsets.all(0),
      onPressed: () {
        showImageViewer(context, imageProvider, onViewerDismissed: () {
          debugPrint("dismissed");
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
              overlays:
                  SystemUiOverlay.values); //显示状态栏、底部按钮栏。然而只适用于点×号，直接返回并不会进入该函数
        }, immersive: false);
        // // 传入了多个图片，则显示可以移动的预览器，单个则显示单个
        // multiImageProvider != null
        //     ? showImageViewerPager(
        //         context,
        //         multiImageProvider!,
        //         onPageChanged: (page) {
        //           debugPrint("$page"); // 因为每个图片都有多个图片预览器，所以会输出多条
        //         },
        //         immersive: false,
        //       )
        //     : showImageViewer(context, imageProvider, onViewerDismissed: () {
        //         debugPrint("dismissed");
        //         SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        //             overlays: SystemUiOverlay
        //                 .values); //显示状态栏、底部按钮栏。然而只适用于点×号，直接返回并不会进入该函数
        //       }, immersive: false);
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5), // 圆角
          child: Image.file(
            File(imageLocalPath),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
