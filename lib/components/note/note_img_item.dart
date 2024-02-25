import 'package:flutter/material.dart';

import 'package:flutter_test_future/components/common_image.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';
import 'package:flutter_test_future/pages/modules/note_img_viewer.dart';
import 'package:flutter_test_future/routes/get_route.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/values/theme.dart';

// 网格的单个笔记图片构建
// 使用：笔记列表页
class NoteImgItem extends StatelessWidget {
  final List<RelativeLocalImage>
      relativeLocalImages; // 传入该网格的所有图片，是因为需要点击该图片(传入的下标)后能够进入图片浏览页面
  final int initialIndex; // 传入多个图片的起始下标
  final int imageRemainCount; // 笔记列表页：第9张图显示剩余图片数量
  final bool useCustomAspectRatio;
  final double aspectRatio;
  final void Function()? onLongPress;
  const NoteImgItem(
      {required this.relativeLocalImages,
      this.initialIndex = 0,
      this.imageRemainCount = 0,
      this.aspectRatio = 4 / 3,
      this.useCustomAspectRatio = false,
      this.onLongPress,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String relativeImagePath = relativeLocalImages[initialIndex].path;

    return InkWell(
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(AppTheme.noteImgRadius),
      onTap: () {
        RouteUtil.toImageViewer(
          context,
          ImageViewerPage(
              relativeLocalImages: relativeLocalImages,
              initialIndex: initialIndex),
        );
      },
      child: Stack(children: [
        AspectRatio(
          aspectRatio: useCustomAspectRatio ? aspectRatio : 1,
          // 圆角
          child: _buildImage(relativeImagePath),
        ),
        imageRemainCount > 0
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.noteImgRadius),
                  color: const Color.fromRGBO(0, 0, 0, 0.5),
                ),
                child: Center(
                  child: Text("+$imageRemainCount",
                      textScaleFactor: 2,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              )
            : Container()
      ]),
    );
  }

  _buildImage(String relativeImagePath) {
    return ClipRRect(
      borderRadius: useCustomAspectRatio
          ? BorderRadius.zero
          : BorderRadius.circular(AppTheme.noteImgRadius),
      child: CommonImage(ImageUtil.getAbsoluteNoteImagePath(relativeImagePath)),
    );
  }
}
