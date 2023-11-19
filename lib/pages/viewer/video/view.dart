import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/pages/viewer/video/logic.dart';
import 'package:flutter_test_future/utils/platform.dart';
import 'package:flutter_test_future/utils/time_util.dart';
import 'package:flutter_test_future/widgets/float_button.dart';
import 'package:flutter_test_future/widgets/gradient_bar.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({required this.path, this.title = '', Key? key})
      : super(key: key);
  final String path;
  final String title;

  @override
  State<VideoPlayerPage> createState() => VideoPlayerPageState();
}

class VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerLogic logic = VideoPlayerLogic(path: widget.path);

  String get title => widget.title.isEmpty
      ? p.basenameWithoutExtension(widget.path)
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
            if (PlatformUtil.isDesktop) logic.playOrPause();
          },
          onDoubleTapDown: (details) {
            // 移动端双击播放/暂停
            // 不能放在onDoubleTapDown，可能是会和自带的快进和后退10s冲突(即使关闭了也不行)
            if (PlatformUtil.isMobile) logic.playOrPause();
          },
          onDoubleTap: () {
            // 桌面端双击进入/退出全屏
            if (PlatformUtil.isDesktop) logic.windowEnterOrExitFullscreen();
          },
          onLongPressStart: (details) => logic.longPressToSpeedUp(),
          onLongPressUp: () => logic.cancelSpeedUp(),
          onHorizontalDragStart: (details) => logic.videoController.pause(),
          onHorizontalDragUpdate: (details) =>
              logic.calculateWillSeekPosition(details.delta.dx),
          onHorizontalDragEnd: (details) => logic.seekDragEndPosition(),
          child: Stack(
            children: [
              _buildVideoView(),
              _buildBufferingWidget(),
              _buildTopBar(),
              _buildBottomBar(),
              _buildFastForwarding(),
              _buildDragSeekPosition(),
              // _buildScreenShotFloatButton(),
              _buildScreenShotPreview(),
            ],
          )),
    );
  }

  _buildTopBar() {
    return Positioned(
        left: 0,
        top: 0,
        child: SizedBox(
            height: 60,
            width: MediaQuery.of(context).size.width,
            child: Row(children: _buildTopBarWidgets(context))));
  }

  _buildBufferingWidget() {
    if (!logic.buffering) return const SizedBox();
    return Container(
      color: Colors.black12,
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: const Align(
        alignment: Alignment.center,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }

  _buildBottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: GradientBar(
        reverse: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProgressBar(),
            Row(
              children: [
                _buildPlayOrPauseButton(),
                const Spacer(),
                _buildFullscreenButton(),
              ],
            )
          ],
        ),
      ),
    );
  }

  _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          Text(
            TimeUtil.getReadableDuration(Duration(milliseconds: logic.curMs)),
            style: const TextStyle(color: Colors.white),
          ),
          Expanded(
            child: Stack(
              children: [
                // 缓冲条显示在底部，避免遮挡进度条
                if (logic.videoController.value.buffered.isNotEmpty)
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2, // 轨迹高度
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 0, // 滑块大小
                      ),
                      activeTrackColor: Colors.white.withOpacity(0.5),
                      inactiveTrackColor: Colors.transparent,
                      trackShape: const RectangularSliderTrackShape(),
                    ),
                    child: Slider(
                      value: logic.curBufferedMs / logic.totalMs.toDouble(),
                      onChanged: (double value) {},
                    ),
                  ),
                // 进度条
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbColor: Theme.of(context).primaryColor,
                    activeTrackColor: Theme.of(context).primaryColor,
                    inactiveTrackColor: Colors.grey.shade800,
                  ),
                  child: Slider(
                    min: 0,
                    max: logic.totalMs.toDouble(),
                    value: logic.curMs.toDouble(),
                    onChangeStart: (value) {
                      // 开始拖动时，暂停
                      logic.pause();
                    },
                    onChangeEnd: (value) {
                      // 恢复播放
                      logic.play();
                    },
                    onChanged: (value) {
                      int seekMs = value.toInt();

                      logic.videoController
                          .seekTo(Duration(milliseconds: seekMs));
                    },
                  ),
                ),
              ],
            ),
          ),
          Text(
            TimeUtil.getReadableDuration(Duration(milliseconds: logic.totalMs)),
            style: const TextStyle(color: Colors.white),
          )
        ],
      ),
    );
  }

  _buildPlayOrPauseButton() {
    return IconButton(
        onPressed: () => logic.playOrPause(),
        icon: Icon(
          logic.videoController.value.isPlaying
              ? Icons.pause
              : Icons.play_arrow,
          color: Colors.white,
        ));
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

  List<Widget> _buildTopBarWidgets(BuildContext context) {
    return [
      Row(
        children: [
          IconButton(
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

  _buildVideoView() => logic.videoController.value.isInitialized
      ? VideoPlayer(logic.videoController)
      : Container(color: Colors.black);

  _buildScreenShotPreview() {
    var radius = BorderRadius.circular(6);
    var width = MediaQuery.of(context).size.width / 4;

    if (logic.capturing) {
      return Container(
        alignment: Alignment.topRight,
        padding: EdgeInsets.fromLTRB(0, Global.getAppBarHeight(context), 20, 0),
        child: AspectRatio(
          aspectRatio: logic.videoController.value.aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: radius,
            ),
            child: const LoadingWidget(center: true),
          ),
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
