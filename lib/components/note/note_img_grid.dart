import 'package:flutter/material.dart';
import 'package:animetrace/components/note/note_img_item.dart';
import 'package:animetrace/models/relative_local_image.dart';
import 'package:animetrace/widgets/responsive.dart';
import 'package:animetrace/utils/sp_profile.dart';
import 'package:animetrace/values/values.dart';

// 用于显示笔记图片网格
// 使用：笔记列表页
class NoteImgGrid extends StatelessWidget {
  final List<RelativeLocalImage> relativeLocalImages;
  final limitShowImageNum = true;

  const NoteImgGrid({Key? key, required this.relativeLocalImages})
      : super(key: key);

  bool get useFillStyle => false;
  // 是否开启显示所有图片配置
  bool get enableShowAllNoteGridImage => false;

  @override
  Widget build(BuildContext context) {
    // 没有图片则直接返回
    if (relativeLocalImages.isEmpty) {
      return Container();
    }

    // 构建网格图片
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
      child: Responsive(
          responsiveWidthSource: ResponsiveWidthSource.constraints,
          // mobile: _buildMobileView(),
          mobile: _buildView(columnCnt: 3, maxDisplayCount: 9),
          tablet: _buildView(columnCnt: 5, maxDisplayCount: 10),
          desktop: _buildView(columnCnt: 6, maxDisplayCount: 12)),
    );
  }

  // ignore: unused_element
  _buildMobileView() {
    final imageCount = relativeLocalImages.length;

    Widget? child;
    int columnCount = 3, maxDisplayCount = 9;
    double childAspectRatio = 1;

    if (imageCount == 1) {
      columnCount = 1;
      childAspectRatio = 16 / 9;
    }

    if (imageCount == 2) {
      columnCount = 2;
      childAspectRatio = 4 / 3;
    }

    if (imageCount == 3) {
      columnCount = 3;
      childAspectRatio = 4 / 3;
    }

    if (imageCount == 4) {
      columnCount = 2;
      childAspectRatio = 4 / 3;
    }

    if (imageCount == 6) {
      columnCount = 3;
      childAspectRatio = 4 / 3;
    }

    if (imageCount >= 9) {
      columnCount = 3;
      maxDisplayCount = 9;
      childAspectRatio = 1;
    }

    if (imageCount == 5 || imageCount == 7 || imageCount == 8) {
      columnCount = 3;
      maxDisplayCount = 9;
      childAspectRatio = 1;
    }

    child = _buildCommonGrid(
      columnCnt: columnCount,
      maxDisplayCount: maxDisplayCount,
      childAspectRatio: childAspectRatio,
    );

    if (imageCount == 3) {
      columnCount = 3;
      childAspectRatio = 4 / 3;

      // 左边上下两张，右边一张
      child = Row(
        children: [
          Expanded(
            child: Column(
              children: [
                NoteImgItem(
                  useCustomAspectRatio: true,
                  aspectRatio: childAspectRatio,
                  relativeLocalImages: relativeLocalImages,
                  initialIndex: 0,
                ),
                SizedBox(height: AppTheme.noteImageSpacing),
                NoteImgItem(
                  useCustomAspectRatio: true,
                  aspectRatio: childAspectRatio,
                  relativeLocalImages: relativeLocalImages,
                  initialIndex: 1,
                )
              ],
            ),
          ),
          SizedBox(width: AppTheme.noteImageSpacing),
          Expanded(
              child: NoteImgItem(
            useCustomAspectRatio: true,
            aspectRatio: 4 / (3 * 2),
            relativeLocalImages: relativeLocalImages,
            initialIndex: 2,
          ))
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: child,
    );
  }

  _buildView({int columnCnt = 3, int maxDisplayCount = 9}) {
    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: _buildCommonGrid(
          columnCnt: columnCnt, maxDisplayCount: maxDisplayCount),
    );
  }

  _buildCommonGrid({
    required int columnCnt,
    required int maxDisplayCount,
    double childAspectRatio = 1,
  }) {
    bool showAllNoteGridImage = SpProfile.getShowAllNoteGridImage();
    if (!enableShowAllNoteGridImage) showAllNoteGridImage = false;

    return GridView.builder(
      // ListView嵌套GridView
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // WithMaxCrossAxisExtent无法获取列数，所以无法得知应该只显示多少图片。因此需要委托给WithFixedCrossAxisCount指定列数
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCnt, // 横轴数量
        crossAxisSpacing: AppTheme.noteImageSpacing, // 横轴距离
        mainAxisSpacing: AppTheme.noteImageSpacing, // 竖轴距离
        childAspectRatio: childAspectRatio, // 网格比例
      ),
      itemCount: showAllNoteGridImage
          ? relativeLocalImages.length
          : _getGridItemCount(maxDisplayCount),
      itemBuilder: (context, index) {
        // Log.info("$runtimeType: index=$index");
        return NoteImgItem(
            useCustomAspectRatio: useFillStyle,
            aspectRatio: childAspectRatio,
            relativeLocalImages: relativeLocalImages,
            initialIndex: index,
            // 避免穿透到卡片笔记长按效果
            onLongPress: () {},
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
