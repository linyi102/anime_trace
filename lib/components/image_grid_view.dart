import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/relative_local_image.dart';
import 'package:flutter_test_future/components/error_image_builder.dart';
import 'package:flutter_test_future/components/image_grid_item.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/image_viewer.dart';
import 'package:flutter_test_future/utils/image_util.dart';

class ImageGridView extends StatelessWidget {
  final List<RelativeLocalImage> relativeLocalImages;
  const ImageGridView({Key? key, required this.relativeLocalImages})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 没有图片则直接返回
    if (relativeLocalImages.isEmpty) {
      return Container();
    }
    // 只有一张图片，则16/9比例显示
    if (relativeLocalImages.length == 1) {
      return Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: MaterialButton(
          padding: const EdgeInsets.all(0),
          onPressed: () {
            Navigator.push(
                context,
                FadeRoute(
                    // 因为里面的浏览器切换图片时自带了过渡效果，所以取消这个过渡
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                    builder: (context) {
                      return ImageViewer(
                        relativeLocalImages: [relativeLocalImages[0]],
                        initialIndex: 0,
                      );
                    }));
          },
          child: AspectRatio(
            aspectRatio: 16 / 9, // 固定长宽
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5), // 圆角
              child: Image.file(
                File(ImageUtil.getAbsoluteImagePath(
                    relativeLocalImages[0].path)),
                fit: BoxFit.cover,
                errorBuilder: errorImageBuilder(relativeLocalImages[0].path),
              ),
            ),
          ),
        ),
      );
    } else {
      // 构建网格图片
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
        shrinkWrap: true, // ListView嵌套GridView
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: relativeLocalImages.length == 2 ? 2 : 3, // 横轴数量
          crossAxisSpacing: 5, // 横轴距离
          mainAxisSpacing: 5, // 竖轴距离
          childAspectRatio: 1, // 网格比例。31/43为封面比例
        ),
        itemCount: relativeLocalImages.length,
        itemBuilder: (context, index) {
          return ImageGridItem(
            relativeLocalImages: relativeLocalImages,
            initialIndex: index,
          );
        },
      );
    }
  }
}
