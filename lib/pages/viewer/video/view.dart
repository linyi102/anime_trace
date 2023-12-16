import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/pages/viewer/image/view.dart';
import 'package:flutter_test_future/pages/viewer/video/logic.dart';
import 'package:flutter_test_future/pages/viewer/video/widgets/fixed_material_video_controls.dart'
    as fix_video;
import 'package:flutter_test_future/routes/get_route.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/platform.dart';
import 'package:flutter_test_future/widgets/multi_platform.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:path/path.dart' as p;

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage(
      {required this.url,
      this.title = '',
      this.leading,
      this.whenDesktopToggleFullScreen,
      Key? key})
      : super(key: key);
  final String url;
  final String title;
  final Widget? leading;
  final void Function(bool isFullScreen)? whenDesktopToggleFullScreen;

  @override
  State<VideoPlayerPage> createState() => VideoPlayerPageState();
}

class VideoPlayerPageState extends State<VideoPlayerPage> {
  get logicTag => VideoPlayerLogic.generateTag(widget.url);

  late VideoPlayerLogic logic =
      Get.put(VideoPlayerLogic(url: widget.url), tag: logicTag);

  String get title => widget.title.isEmpty
      ? p.basenameWithoutExtension(widget.url)
      : widget.title;

  @override
  void dispose() {
    Get.delete<VideoPlayerLogic>(tag: logicTag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: logic,
      builder: (_) => GestureDetector(
          onDoubleTapDown: (details) {
            // 移动端双击播放/暂停
            // 不能放在onDoubleTapDown，可能是会和自带的快进和后退10s冲突(即使关闭了也不行)
            if (PlatformUtil.isMobile) logic.player.playOrPause();
          },
          onDoubleTap: () {
            // 桌面端双击进入/退出全屏
            if (PlatformUtil.isDesktop) {
              logic.toggleDesktopFullscreen(
                  whenDesktopToggleFullScreen:
                      widget.whenDesktopToggleFullScreen);
            }
          },
          onTapUp: PlatformUtil.isDesktop
              ? (details) {
                  Log.info(MediaQuery.of(context).size);
                  Log.info(details.globalPosition);
                  // 顶部栏高度60 底部栏高度80
                  final wholeHeight = MediaQuery.of(context).size.height;
                  final dy = details.globalPosition.dy;
                  if (dy > 60 && dy < wholeHeight - 80) {
                    logic.player.playOrPause();
                  }
                }
              : null,
          onLongPressStart: (details) => logic.longPressToSpeedUp(),
          onLongPressUp: () => logic.cancelSpeedUp(),
          onHorizontalDragStart: (details) =>
              logic.onHorizontalDragStart(details),
          onHorizontalDragUpdate: (details) =>
              logic.calculateWillSeekPosition(details),
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
    // BUG: 拖动进度条也会触发，因此Windows禁用
    if (PlatformUtil.isDesktop) return const SizedBox();
    if (logic.willSeekPosition.isEmpty) return const SizedBox();

    return _buildStatusCard(
      logic.willSeekPosition,
      icon: logic.willSeekPositionIsFuture
          ? Icons.fast_forward_rounded
          : Icons.fast_rewind_rounded,
    );
  }

  MultiPlatform _buildMultiPlatformVideoView(BuildContext context) {
    return MultiPlatform(
      mobile: fix_video.MaterialVideoControlsTheme(
        normal: fix_video.MaterialVideoControlsThemeData(
            topButtonBarMargin: const EdgeInsets.symmetric(horizontal: 5),
            topButtonBar: _buildTopBar(context),
            volumeGesture: true,
            brightnessGesture: true,
            // 取消自带的中心播放按钮
            primaryButtonBar: [],
            // 取消双击两侧后退或前进10s
            seekOnDoubleTap: false,
            controlsTransitionDuration: const Duration(milliseconds: 100),
            // 底部进度条移动到底部栏上方
            seekBarMargin: const EdgeInsets.fromLTRB(16, 0, 16, 60),
            seekBarThumbColor: Theme.of(context).primaryColor,
            seekBarPositionColor: Theme.of(context).primaryColor,
            seekBarHeight: 4,
            volumeIndicatorBuilder: (context, value) {
              return _buildStatusCard('${(value * 100).toInt()}%',
                  icon: value == 0
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded);
            },
            brightnessIndicatorBuilder: (context, value) {
              return _buildStatusCard('${(value * 100).toInt()}%',
                  icon: Icons.brightness_7_rounded);
            },
            bottomButtonBar: [
              const MaterialSkipPreviousButton(),
              const MaterialPlayOrPauseButton(),
              const MaterialSkipNextButton(),
              const MaterialPositionIndicator(),
              const Spacer(),
              _buildScreenShotBottomButton(),
            ]),
        fullscreen: const fix_video.MaterialVideoControlsThemeData(),
        child: _buildVideoView(),
      ),
      desktop: MaterialDesktopVideoControlsTheme(
        normal: MaterialDesktopVideoControlsThemeData(
            topButtonBarMargin: const EdgeInsets.symmetric(horizontal: 5),
            topButtonBar: _buildTopBar(context),
            toggleFullscreenOnDoublePress: false,
            seekBarThumbColor: Theme.of(context).primaryColor,
            seekBarPositionColor: Theme.of(context).primaryColor,
            seekBarHeight: 4,
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
    return _buildStatusCard('${logic.fastForwardRate.toInt()} 倍速播放',
        icon: Icons.fast_forward_rounded);
  }

  Align _buildStatusCard(String text, {IconData? icon}) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.only(top: 50),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTopBar(BuildContext context) {
    return [
      Row(
        children: [
          widget.leading != null
              ? widget.leading!
              : IconButton(
                  onPressed: () async {
                    await Global.restoreDevice();
                    Navigator.pop(context);
                  },
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

  _buildVideoView() => Video(
        controller: logic.videoController,
        // 修改controls后，需要重新进入播放页才可以看到效果，热重载无效
        controls:
            PlatformUtil.isMobile ? fix_video.MaterialVideoControls : null,
      );

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
                RouteUtil.materialTo(context,
                    ImageViewerPage(imagePaths: [logic.screenShotFile!.path]));
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
        onPressed: logic.toggleDesktopFullscreen,
        icon:
            const Icon(MingCuteIcons.mgc_fullscreen_line, color: Colors.white));
  }

  _buildScreenShotBottomButton() {
    // return const SizedBox();
    return IconButton(
      icon: const Icon(MingCuteIcons.mgc_camera_2_line, color: Colors.white),
      onPressed: () => logic.capture(),
    );
  }
}
