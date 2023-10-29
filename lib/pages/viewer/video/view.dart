import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/pages/viewer/video/logic.dart';
import 'package:flutter_test_future/utils/platform.dart';
import 'package:flutter_test_future/widgets/float_button.dart';
import 'package:flutter_test_future/widgets/multi_platform.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
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
      builder: (_) => GestureDetector(
          onTap: () {
            // 桌面端单击播放/暂停
            if (PlatformUtil.isDesktop) logic.player.playOrPause();
          },
          onDoubleTap: () {
            // 移动端双击播放/暂停
            if (PlatformUtil.isMobile) logic.player.playOrPause();
            // 桌面端双击进入/退出全屏
            if (PlatformUtil.isDesktop) logic.windowEnterOrExitFullscreen();
          },
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
              // _buildScreenShotFloatButton(),
              _buildScreenShotPreview(),
            ],
          )),
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
          topButtonBarMargin: const EdgeInsets.symmetric(horizontal: 5),
          topButtonBar: _buildTopBar(context),
          volumeGesture: true,
        ),
        fullscreen: MaterialVideoControlsThemeData(
          topButtonBarMargin: const EdgeInsets.symmetric(horizontal: 5),
          topButtonBar: _buildTopBar(context),
          volumeGesture: true,
        ),
        child: _buildVideoView(),
      ),
      desktop: MaterialDesktopVideoControlsTheme(
        normal: MaterialDesktopVideoControlsThemeData(
            topButtonBarMargin: const EdgeInsets.symmetric(horizontal: 5),
            toggleFullscreenOnDoublePress: false,
            topButtonBar: _buildTopBar(context),
            bottomButtonBar: [
              const MaterialDesktopSkipPreviousButton(),
              const MaterialDesktopPlayOrPauseButton(),
              const MaterialDesktopSkipNextButton(),
              const MaterialDesktopVolumeButton(),
              const MaterialDesktopPositionIndicator(),
              const Spacer(),
              _buildScreenShotBottomButton(),
              _buildFullscreenButton()
            ]),
        // 自带的双击和右下角的全屏按钮，进入全屏是通过push一个新页面实现的，会导致手势失效和无法看到Stack上的组件，因此使用windowManager对当前页面进行全屏
        fullscreen: const MaterialDesktopVideoControlsThemeData(),
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
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${logic.fastForwardRate.toInt()} 倍速播放中…',
          style: const TextStyle(color: Colors.white),
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
              fontSize: 18,
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

  _buildVideoView() => Video(controller: logic.videoController);

  _buildScreenShotPreview() {
    var radius = BorderRadius.circular(6);
    var width = MediaQuery.of(context).size.width / 4;

    if (logic.capturing) {
      return Container(
        alignment: Alignment.topRight,
        padding: EdgeInsets.fromLTRB(0, Global.getAppBarHeight(context), 20, 0),
        child: Container(
          height: width *
              ((logic.player.state.height ?? 9) /
                  (logic.player.state.width ?? 16)),
          width: width,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: radius,
          ),
          child: const LoadingWidget(center: true),
        ),
      );
    }

    if (logic.screenShotFile == null) {
      return const SizedBox();
    }

    return Container(
      alignment: Alignment.topRight,
      padding: EdgeInsets.fromLTRB(0, Global.getAppBarHeight(context), 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: radius,
            child: InkWell(
              onTap: () {
                // TODO 移动端打开图片，桌面端打开浏览器定位图片
              },
              child: SizedBox(
                width: width,
                // 使用文件显示截图时，加载时没有高度，因此取消按钮会在上方，加载完毕后下移
                child: Image.file(logic.screenShotFile!),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Material(
            borderRadius: radius,
            color: Colors.white,
            child: InkWell(
              onTap: logic.deleteScreenShotFile,
              borderRadius: radius,
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(borderRadius: radius),
                  width: width,
                  child: const Center(
                      child:
                          Text("删除", style: TextStyle(color: Colors.black)))),
            ),
          ),
        ],
      ),
    );
  }

  _buildFullscreenButton() {
    return IconButton(
        onPressed: logic.windowEnterOrExitFullscreen,
        icon:
            const Icon(MingCuteIcons.mgc_fullscreen_line, color: Colors.white));
  }

  _buildScreenShotBottomButton() {
    return IconButton(
      icon: const Icon(MingCuteIcons.mgc_camera_2_line, color: Colors.white),
      onPressed: () => logic.capture(),
    );
  }

  _buildScreenShotFloatButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: FloatButton(
        icon: MingCuteIcons.mgc_camera_2_line,
        onTap: () => logic.capture(),
      ),
    );
  }
}
