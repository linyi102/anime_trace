import 'dart:io';

import 'package:flutter/material.dart';

class ImageGridItem extends StatelessWidget {
  final String imageLocalPath;
  const ImageGridItem(this.imageLocalPath, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5), // 圆角
        child: Image.file(
          File(imageLocalPath),
          fit: BoxFit.fitHeight,
        ),
      ),
    );
  }
}
