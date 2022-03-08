import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/relative_local_image.dart';
import 'package:flutter_test_future/components/error_image_builder.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/image_viewer.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:transparent_image/transparent_image.dart';

class ImageGridItem extends StatelessWidget {
  final List<RelativeLocalImage> relativeLocalImages;
  final int initialIndex; // 传入多个图片的起始下标
  const ImageGridItem(
      {required this.relativeLocalImages, this.initialIndex = 0, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String relativeImagePath = relativeLocalImages[initialIndex].path;
    String imageLocalPath = ImageUtil.getAbsoluteImagePath(relativeImagePath);

    return MaterialButton(
      padding: const EdgeInsets.all(0),
      onPressed: () {
        Navigator.push(context, FadeRoute(builder: (context) {
          return ImageViewer(
            relativeLocalImages: relativeLocalImages,
            initialIndex: initialIndex,
          );
        }));
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5), // 圆角
          // child: FadeInImage.memoryNetwork(
          //     placeholder: kTransparentImage, image: imageLocalPath),
          child: FadeInImage(
            placeholder: MemoryImage(kTransparentImage),
            image: FileImage(File(imageLocalPath)),
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 300),
            imageErrorBuilder: errorImageBuilder(relativeImagePath),
          ),
          // child: Image.file(
          //   File(imageLocalPath),
          //   fit: BoxFit.cover,
          //   errorBuilder: errorImageBuilder(relativeImagePath),
          // ),
        ),
      ),
    );
  }
}
