import 'package:flutter/material.dart';

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
  const NoteImgItem(
      {required this.relativeLocalImages,
      this.initialIndex = 0,
      this.imageRemainCount = 0,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String relativeImagePath = relativeLocalImages[initialIndex].path;

    return MaterialButton(
      padding: const EdgeInsets.all(0),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(
            // transitionDuration: Duration.zero,
            // reverseTransitionDuration: Duration.zero,
            builder: (context) {
          // 点击图片进入图片浏览页面
          return ImageViewerPage(
              relativeLocalImages: relativeLocalImages,
              initialIndex: initialIndex);
        })).then((value) {
          // if (Global.modifiedNoteImgRootPath) {
          //   // 修改了路径，重新渲染，然后重置
          //   // 注：不应该在这里渲染，因为这只是单个图片，应该渲染所有图片
          //   // 暂时没找到哪里应该执行这段代码，因为上级把该NoteImgItem作为组件，并不是push
          //   Global.modifiedNoteImgRootPath = false;
          // }
        });
      },
      child: Stack(children: [
        // 正方形
        AspectRatio(
          aspectRatio: 1,
          // 圆角
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: CommonImage(
                ImageUtil.getAbsoluteNoteImagePath(relativeImagePath)),
          ),
        ),
        imageRemainCount > 0
            ? Container(
                color: const Color.fromRGBO(0, 0, 0, 0.5),
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
