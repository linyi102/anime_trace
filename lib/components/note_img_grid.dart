import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/note_img_item.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';
import 'package:flutter_test_future/responsive.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';

// 用于显示笔记图片网格
// 使用：笔记列表页
class NoteImgGrid extends StatelessWidget {
  final List<RelativeLocalImage> relativeLocalImages;
  final limitShowImageNum = true;

  const NoteImgGrid({Key? key, required this.relativeLocalImages})
      : super(key: key);

  get crossAxisSpacing => 2.0;
  get mainAxisSpacing => 2.0;
  get enableTwitterStyle => false;
  // 是否开启显示所有图片配置
  get enableShowAllNoteGridImage => false;

  @override
  Widget build(BuildContext context) {
    // 没有图片则直接返回
    if (relativeLocalImages.isEmpty) {
      return Container();
    }

    // 构建网格图片
    return Responsive(
        mobile: _buildView(columnCnt: 3, maxDisplayCount: 9),
        tablet: _buildView(columnCnt: 5, maxDisplayCount: 10),
        desktop: _buildView(columnCnt: 6, maxDisplayCount: 12));
  }

  _buildView({int columnCnt = 3, int maxDisplayCount = 9}) {
    late Widget twitterGrid;
    if (enableTwitterStyle) {
      double childAspectRatio = 4 / 3;

      if (relativeLocalImages.length <= 2) {
        columnCnt = relativeLocalImages.length;
      }

      if (relativeLocalImages.length >= 4) {
        columnCnt = 2;
        maxDisplayCount = 4;
      }

      twitterGrid = _buildCommonGrid(
        columnCnt: columnCnt,
        maxDisplayCount: maxDisplayCount,
        childAspectRatio: childAspectRatio,
      );

      if (relativeLocalImages.length == 3) {
        // 左边上下两张，右边一张
        twitterGrid = Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  NoteImgItem(
                    twitterStyle: true,
                    aspectRatio: childAspectRatio,
                    relativeLocalImages: relativeLocalImages,
                    initialIndex: 0,
                  ),
                  SizedBox(height: mainAxisSpacing),
                  NoteImgItem(
                    twitterStyle: true,
                    aspectRatio: childAspectRatio,
                    relativeLocalImages: relativeLocalImages,
                    initialIndex: 1,
                  )
                ],
              ),
            ),
            SizedBox(width: crossAxisSpacing),
            Expanded(
                child: NoteImgItem(
              twitterStyle: true,
              aspectRatio: 4 / (3 * 2),
              relativeLocalImages: relativeLocalImages,
              initialIndex: 2,
            ))
          ],
        );
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
      child: ClipRRect(
        borderRadius:
            enableTwitterStyle ? BorderRadius.circular(12) : BorderRadius.zero,
        child: enableTwitterStyle
            ? twitterGrid
            : _buildCommonGrid(
                columnCnt: columnCnt, maxDisplayCount: maxDisplayCount),
      ),
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
        crossAxisSpacing: crossAxisSpacing, // 横轴距离
        mainAxisSpacing: mainAxisSpacing, // 竖轴距离
        childAspectRatio: childAspectRatio, // 网格比例
      ),
      itemCount: showAllNoteGridImage
          ? relativeLocalImages.length
          : _getGridItemCount(maxDisplayCount),
      itemBuilder: (context, index) {
        // Log.info("$runtimeType: index=$index");
        return NoteImgItem(
            twitterStyle: enableTwitterStyle,
            aspectRatio: childAspectRatio,
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
