import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test_future/utils/regexp.dart';
import 'package:flutter_test_future/utils/time_util.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

class VideoPlayerLogic extends GetxController {
  late final VideoPlayerController videoController;
  final String path;

  VideoPlayerLogic({required this.path});

  List<void Function()> videoListeners = []; // 监听

  /// 属性
  int totalMs = 0; // 总时长
  int _curMs = 0; // 当前播放进度
  int curBufferedMs = 0; // 当前缓冲进度
  int preLatestMs = 0; // 记录上次监听到的最新进度
  bool buffering = false; // 为true时表示正在缓冲视频，此时在中心显示加载圈

  int get curMs => _curMs > totalMs ? 0 : _curMs;

  /// 长按倍速播放
  double get fastForwardRate => 3;
  bool fastForwarding = false;

  /// 左右拖动进度
  double totalDx = 0; // 左右滑动过程中累计的dx
  int destSeconds = 0; // 最终要跳转的描述
  String willSeekPosition = ''; // 拖动时展示的文字

  /// 截图
  File? screenShotFile; // 截图文件
  bool capturing = false;

  @override
  void onInit() {
    videoListeners.add(_positionListener);
    videoListeners.add(_bufferProgressListener);
    videoListeners.add(_bufferingListener);

    super.onInit();
    if (RegexpUtil.isUrl(path)) {
      videoController = VideoPlayerController.networkUrl(Uri.parse(path));
    } else {
      videoController = VideoPlayerController.file(File(path));
    }

    videoController.initialize().then((_) {
      update();
      videoController.play();

      totalMs = videoController.value.duration.inMilliseconds;
      for (var element in videoListeners) {
        videoController.addListener(element);
      }
      WakelockPlus.enable();
    });
  }

  @override
  void onClose() {
    videoController.dispose();
    WakelockPlus.disable();
    super.onClose();
  }

  play() {
    videoController.play();
    update();
  }

  pause() {
    videoController.pause();
    update();
  }

  playOrPause() {
    if (videoController.value.isPlaying) {
      videoController.pause();
    } else {
      videoController.play();
    }
    update();
  }

  longPressToSpeedUp() {
    if (!videoController.value.isPlaying) return;

    videoController.setPlaybackSpeed(fastForwardRate);
    fastForwarding = true;
    update();
  }

  cancelSpeedUp() {
    videoController.setPlaybackSpeed(1);
    fastForwarding = false;
    update();
  }

  calculateWillSeekPosition(double dx) {
    totalDx += dx;
    // 根据最终位移，计算出快进/后退的秒数
    int secondsGap = totalDx.abs() ~/ 5;
    // 获取当前视频播放的进度秒数
    int curSeconds = videoController.value.position.inSeconds;
    // 要跳转的进度秒数
    destSeconds = curSeconds;

    if (totalDx > 0) {
      destSeconds += secondsGap;
      // 如果快进到最大秒数，则修正为最大秒数
      if (destSeconds > videoController.value.duration.inSeconds) {
        destSeconds = videoController.value.duration.inSeconds;
      }

      willSeekPosition =
          "${TimeUtil.getReadableDuration(Duration(seconds: destSeconds))}\n[+${TimeUtil.getReadableDuration(Duration(seconds: secondsGap))}]";
    } else if (totalDx < 0) {
      destSeconds -= secondsGap;
      // 如果后退至开头，则修正为0
      if (destSeconds < 0) destSeconds = 0;

      willSeekPosition =
          "${TimeUtil.getReadableDuration(Duration(seconds: destSeconds))}\n[-${TimeUtil.getReadableDuration(Duration(seconds: secondsGap))}]";
    }
    update();
  }

  seekDragEndPosition() async {
    // 寻找并播放
    await videoController.seekTo(Duration(seconds: destSeconds));
    videoController.play();
    // 重置
    totalDx = 0;
    destSeconds = 0;
    willSeekPosition = '';
    update();
  }

  windowEnterOrExitFullscreen() async {
    await windowManager.setFullScreen(!await windowManager.isFullScreen());
    if (!await windowManager.isFullScreen()) {
      // 不是全屏时，重新设置宽高。因为全屏后退出全屏会导致无法展示当前页的所有信息
      var size = await windowManager.getSize();
      await windowManager.setSize(Size(size.width, size.height - 0.1));
      windowManager.setSize(Size(size.width, size.height));
    }
  }

  capture() async {
    _handleError(String msg) {
      ToastUtil.showText(msg);
      capturing = false;
      update();
    }

    capturing = true;
    update();

    late Uint8List? uint8list;
    try {
      // uint8list = await videoController.screenshot();
      uint8list = null;
    } catch (e) {
      _handleError("截图出错：$e");
      return;
    }

    if (uint8list == null) {
      _handleError("截图失败");
      return;
    }

    String? rootPath = (await getDownloadsDirectory())?.path;
    if (rootPath == null) {
      _handleError("无法获取到保存路径");
      return;
    }

    // 图片保存到文件中
    String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
    File file = File(p.join(rootPath, '漫迹', 'capture', fileName));
    await file.create(recursive: true);
    await file.writeAsBytes(uint8list);

    screenShotFile = file;
    capturing = false;
    // 重绘，显示截图
    update();

    // 3s后自动消失
    await Future.delayed(const Duration(seconds: 3));
    // 如果3s后还是之前的文件，那么就消失掉，否则是3s内又进行了截图
    if (screenShotFile?.path == file.path) {
      screenShotFile = null;
      update();
    }
  }

  deleteScreenShotFile() {
    screenShotFile?.delete().then((value) {
      ToastUtil.showText('已删除');
    });
    screenShotFile = null;
    update();
  }

  /// 监听是否在缓冲
  _bufferingListener() {
    bool latestBuffering = videoController.value.isBuffering;
    if (buffering != latestBuffering) {
      buffering = latestBuffering;
      update();
    }
  }

  /// 监听缓冲进度(暂停时也要更新缓冲进度)
  _bufferProgressListener() {
    // TODO 会提示No Element
    // int latestBufferedMs =
    //     videoController.value.buffered.last.end.inMilliseconds;

    // if (latestBufferedMs < totalMs &&
    //     (latestBufferedMs - curBufferedMs).abs() < 1000) return;

    // curBufferedMs = latestBufferedMs;
    // update();
  }

  /// 监听播放进度
  _positionListener() {
    // 获取最新播放进度
    int latestMs = videoController.value.position.inMilliseconds;

    // 监听时同一个进度会收到两次，因此如果最新进度和上次一致，那么直接返回
    // 好处：避免播放结束后，也会收到两次导致弹出两条提示没有下一个视频
    if (latestMs == preLatestMs) return;
    preLatestMs = latestMs;
    // Log.info("_positionListener: latestMs=$latestMs");

    // 如果没有结束(避免因相差过小而无法更新到结束)，且相差过小，直接跳过，不更新进度条
    if (latestMs < totalMs && (latestMs - _curMs).abs() < 1000) return;

    // 更新进度条
    _curMs = latestMs;
    update();

    if (latestMs == totalMs) {
      // 播放结束
    }
  }
}
