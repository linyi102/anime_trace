import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/note_img_item.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';
import 'package:flutter_test_future/responsive.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sp_util.dart';

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
  }

  GridView _buildGridView({int columnCnt = 3, int maxDisplayCount = 9}) {
    double crossAxisSpacing = 4;
    double mainAxisSpacing = 4;
    double childAspectRatio = 1;

    bool showAllNoteGridImage = SpProfile.getShowAllNoteGridImage();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
      // ListView嵌套GridView
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // WithMaxCrossAxisExtent无法获取列数，所以无法得知应该只显示多少图片。因此需要委托给WithFixedCrossAxisCount指定列数
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCnt, // 横轴数量
        crossAxisSpacing: crossAxisSpacing, // 横轴距离
        mainAxisSpacing: mainAxisSpacing, // 竖轴距离
        childAspectRatio: childAspectRatio, // 网格比例
      ),
      itemCount: showAllNoteGridImage
          ? relativeLocalImages.length
          : _getGridItemCount(maxDisplayCount),
      itemBuilder: (context, index) {
        // debugPrint("$runtimeType: index=$index");
        return NoteImgItem(
            relativeLocalImages: relativeLocalImages,
            initialIndex: index,
            imageRemainCount: showAllNoteGridImage
                ? 0 // 如果设置的是显示所有图片，则不处理剩余图片数量
                : index == maxDisplayCount - 1
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
