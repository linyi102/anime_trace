import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/relative_local_image.dart';
import 'package:flutter_test_future/components/image_grid_item.dart';

// 用于显示笔记图片网格
// 使用：笔记列表页
class ImageGridView extends StatelessWidget {
  final List<RelativeLocalImage> relativeLocalImages;
  final limitShowImageNum = true;

  ImageGridView({Key? key, required this.relativeLocalImages})
      : super(key: key);

  // 手机端最多显示9张，每行3个；电脑端最多显示12张，每行6个
  int maxDisplayCount = Platform.isWindows ? 12 : 9;
  int columnCnt = Platform.isWindows ? 6 : 3;

  @override
  Widget build(BuildContext context) {
    // 没有图片则直接返回
    if (relativeLocalImages.isEmpty) {
      return Container();
    }
    // 构建网格图片
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
      shrinkWrap: true,
      // ListView嵌套GridView
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCnt, // 横轴数量
        crossAxisSpacing: 5, // 横轴距离
        mainAxisSpacing: 5, // 竖轴距离
        childAspectRatio: 1, // 网格比例。31/43为封面比例
      ),
      itemCount: _getGridItemCount(),
      itemBuilder: (context, index) {
        return ImageGridItem(
            relativeLocalImages: relativeLocalImages,
            initialIndex: index,
            imageRemainCount: index == maxDisplayCount - 1
                ? relativeLocalImages.length - maxDisplayCount
                : 0);
      },
    );
    // }
  }

  _getGridItemCount() {
    if (relativeLocalImages.length <= maxDisplayCount) {
      return relativeLocalImages.length;
    }
    if (limitShowImageNum) return maxDisplayCount;
  }
}
