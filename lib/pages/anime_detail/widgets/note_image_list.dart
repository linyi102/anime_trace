import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_image.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/pages/modules/note_img_viewer.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/values/values.dart';

class NoteImageHorizontalListView extends StatefulWidget {
  const NoteImageHorizontalListView({required this.note, super.key});
  final Note note;

  @override
  State<NoteImageHorizontalListView> createState() =>
      _NoteImageHorizontalListViewState();
}

class _NoteImageHorizontalListViewState
    extends State<NoteImageHorizontalListView> {
  final noteImageScrollController = ScrollController();
  bool playing = false;

  double get wholeHorizontalPadding => 10.0;
  double get imageWidth => 120;
  bool get enableControlDarkBg => false;

  @override
  void dispose() {
    noteImageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: wholeHorizontalPadding),
      height: 120,
      child: Stack(
        children: [
          ListView.builder(
              controller: noteImageScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.note.relativeLocalImages.length,
              itemBuilder: (context, imgIdx) {
                // Log.info("横向图片imgIdx=$imgIdx");
                return _buildImageItem(context, imgIdx);
              }),
          if (widget.note.relativeLocalImages.length > 2) _buildControlButton()
        ],
      ),
    );
  }

  Center _buildImageItem(BuildContext context, int imgIdx) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(AppTheme.noteImageSpacing / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.noteImgRadius),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              // 点击图片进入图片浏览页面
              return ImageViewerPage(
                relativeLocalImages: widget.note.relativeLocalImages,
                initialIndex: imgIdx,
              );
            }));
          },
          child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.noteImgRadius),
              child: SizedBox(
                height: 80,
                width: imageWidth,
                child: CommonImage(ImageUtil.getAbsoluteNoteImagePath(
                    widget.note.relativeLocalImages[imgIdx].path)),
              )),
        ),
      ),
    );
  }

  Positioned _buildControlButton() {
    return Positioned(
      right: 0,
      bottom: 15,
      child: GestureDetector(
        onTap: () {
          playing ? _pause() : _play();
          setState(() {
            playing = !playing;
          });
        },
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: enableControlDarkBg
                ? BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(99))
                : null,
            child: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 18,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }

  void _play() async {
    // 如果在末尾，那么先从跳转到起始位置，然后再播放
    if (noteImageScrollController.position.pixels >=
        noteImageScrollController.position.maxScrollExtent) {
      noteImageScrollController.jumpTo(0);
      await Future.delayed(const Duration(milliseconds: 600));
    }

    var realImageWidth = imageWidth + AppTheme.noteImageSpacing / 2;
    var allImageCount = widget.note.relativeLocalImages.length;
    // 左侧已隐藏的图片数量
    var leftImageCount = noteImageScrollController.offset / realImageWidth;
    // 正在展示的图片数量
    var middleImageCount =
        (MediaQuery.of(context).size.width - wholeHorizontalPadding * 2) /
            realImageWidth;
    // 右侧未显示的图片数量
    var rightImageCount = allImageCount - leftImageCount - middleImageCount;
    // 每秒图片1张，注意如果剩余数量小于1，直接使用秒数转int可能会得到0，会导致抛出异常
    // 因此单位使用毫秒
    var ms = (rightImageCount * 1000).toInt();
    // 如果ms小于0，
    if (ms < 0) ms = 1000;

    noteImageScrollController
        .animateTo(noteImageScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: ms), curve: Curves.linear)
        .then((value) {
      // 在自动滚动过程中手动滚动时会立即结束
      Log.info('滚动结束');
      // 滚动结束后重绘为暂停状态
      if (mounted) {
        setState(() {
          playing = false;
        });
      }
    });
  }

  void _pause() {
    noteImageScrollController.animateTo(noteImageScrollController.offset,
        duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }
}
