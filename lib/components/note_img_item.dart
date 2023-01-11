import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/components/common_image.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';
import 'package:flutter_test_future/pages/modules/note_img_viewer.dart';
import 'package:flutter_test_future/utils/image_util.dart';

// 网格的单个笔记图片构建
// 使用：笔记列表页
class NoteImgItem extends StatelessWidget {
  final List<RelativeLocalImage>
      relativeLocalImages; // 传入该网格的所有图片，是因为需要点击该图片(传入的下标)后能够进入图片浏览页面
  final int initialIndex; // 传入多个图片的起始下标
  final int imageRemainCount; // 笔记列表页：第9张图显示剩余图片数量
  NoteImgItem(
      {required this.relativeLocalImages,
      this.initialIndex = 0,
      this.imageRemainCount = 0,
      Key? key})
      : super(key: key);

  bool dirChangedWrapper = false;

  @override
  Widget build(BuildContext context) {
    String relativeImagePath = relativeLocalImages[initialIndex].path;

    return MaterialButton(
      padding: const EdgeInsets.all(0),
      onPressed: () {
        Navigator.push(context, FadeRoute(
            // transitionDuration: Duration.zero,
            // reverseTransitionDuration: Duration.zero,
            builder: (context) {
          // 点击图片进入图片浏览页面
          return ImageViewer(
              relativeLocalImages: relativeLocalImages,
              initialIndex: initialIndex);
        })).then((dirChanged) {
          if (dirChanged) {
            dirChangedWrapper = true;
          }
        });
      },
      child: Stack(children: [
        AspectRatio(
          aspectRatio: 1, // 正方形
          child: ClipRRect(
            // 无效，不会重新渲染，可能是因为是无状态组件
            key: Key("$initialIndex:$dirChangedWrapper"),
            // 圆角
            borderRadius: BorderRadius.circular(5),
            child: CommonImage(ImageUtil.getAbsoluteNoteImagePath(relativeImagePath)),
          ),
        ),
        imageRemainCount > 0
            ? Container(
                color: const Color.fromRGBO(0, 0, 0, 0.2),
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
}
