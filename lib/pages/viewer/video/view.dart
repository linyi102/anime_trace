import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/viewer/video/logic.dart';
import 'package:flutter_test_future/widgets/multi_platform.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({required this.url, this.title = '', Key? key})
      : super(key: key);
  final String url;
  final String title;

  @override
  State<VideoPlayerPage> createState() => VideoPlayerPageState();
}

class VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerLogic logic = VideoPlayerLogic(url: widget.url);

  String get title => widget.title.isEmpty
      ? p.basenameWithoutExtension(widget.url)
      : widget.title;

  @override
  void dispose() {
    Get.delete<VideoPlayerLogic>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: logic,
      builder: (_) => Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          // progressIndicatorTheme:
          //     ProgressIndicatorThemeData(color: Theme.of(context).primaryColor),
        ),
        child: GestureDetector(
            onLongPressStart: (details) => logic.longPressToSpeedUp(),
            onLongPressUp: () => logic.cancelSpeedUp(),
            onHorizontalDragStart: (details) => logic.player.pause(),
            onHorizontalDragUpdate: (details) =>
                logic.calculateWillSeekPosition(details.delta.dx),
            onHorizontalDragEnd: (details) => logic.seekDragEndPosition(),
            child: Stack(
              children: [
                _buildMultiPlatformVideoView(context),
                _buildFastForwarding(),
                _buildDragSeekPosition(),
              ],
            )),
      ),
    );
  }

  /// 左右拖动改变进度位置
  _buildDragSeekPosition() {
    if (logic.willSeekPosition.isEmpty) return const SizedBox();
    return Align(
      alignment: Alignment.center,
      child: Text(
        logic.willSeekPosition,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(blurRadius: 3, color: Colors.black),
            ]),
        textAlign: TextAlign.center,
      ),
    );
  }

  MultiPlatform _buildMultiPlatformVideoView(BuildContext context) {
    return MultiPlatform(
      mobile: MaterialVideoControlsTheme(
        normal: MaterialVideoControlsThemeData(
          topButtonBar: _buildTopBar(context),
          volumeGesture: true,
        ),
        fullscreen: MaterialVideoControlsThemeData(
          topButtonBar: _buildTopBar(context),
          volumeGesture: true,
        ),
        child: _buildVideoView(),
      ),
      desktop: MaterialDesktopVideoControlsTheme(
        normal: MaterialDesktopVideoControlsThemeData(
          topButtonBar: _buildTopBar(context),
        ),
        fullscreen: MaterialDesktopVideoControlsThemeData(
          topButtonBar: _buildTopBar(context),
        ),
        child: _buildVideoView(),
      ),
    );
  }

  /// 长按倍速播放
  _buildFastForwarding() {
    if (!logic.fastForwarding) return const SizedBox();
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.only(top: 80),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '3 倍速播放中…',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  List<Widget> _buildTopBar(BuildContext context) {
    return [
      Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              size: 20,
              color: Colors.white,
              shadows: _shadows,
            ),
          ),
          const SizedBox(width: 15),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              shadows: _shadows,
            ),
          ),
        ],
      )
    ];
  }

  List<Shadow> get _shadows =>
      [const Shadow(blurRadius: 3, color: Colors.black)];

  Video _buildVideoView() => Video(controller: logic.videoController);
}
