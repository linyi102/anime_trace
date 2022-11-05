import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/note_img_item.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';
import 'package:flutter_test_future/responsive.dart';

// 用于显示笔记图片网格
// 使用：笔记列表页
class NoteImgGrid extends StatelessWidget {
  final List<RelativeLocalImage> relativeLocalImages;
  final limitShowImageNum = true;

  const NoteImgGrid({Key? key, required this.relativeLocalImages})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 没有图片则直接返回
    if (relativeLocalImages.isEmpty) {
      return Container();
    }
    // 构建网格图片
    return Responsive(
        mobile: _buildGridView(columnCnt: 3, maxDisplayCount: 9),
        tablet: _buildGridView(columnCnt: 5, maxDisplayCount: 10),
        desktop: _buildGridView(columnCnt: 6, maxDisplayCount: 12));
    // }
  }

  GridView _buildGridView(
      {required int columnCnt, required int maxDisplayCount}) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
      shrinkWrap: true,
      // ListView嵌套GridView
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCnt, // 横轴数量
        crossAxisSpacing: 4, // 横轴距离
        mainAxisSpacing: 4, // 竖轴距离
        childAspectRatio: 1, // 网格比例。31/43为封面比例
      ),
      itemCount: _getGridItemCount(maxDisplayCount),
      itemBuilder: (context, index) {
        // debugPrint("$runtimeType: index=$index");
        return NoteImgItem(
            relativeLocalImages: relativeLocalImages,
            initialIndex: index,
            imageRemainCount: index == maxDisplayCount - 1
                ? relativeLocalImages.length - maxDisplayCount
                : 0);
      },
    );
  }

  _getGridItemCount(int maxDisplayCount) {
    if (relativeLocalImages.length <= maxDisplayCount) {
      return relativeLocalImages.length;
    }
    if (limitShowImageNum) return maxDisplayCount;
  }
}
