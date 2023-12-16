import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/file_util.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/permission.dart';
import 'package:flutter_test_future/utils/platform.dart';
import 'package:flutter_test_future/utils/time_util.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

class VideoPlayerLogic extends GetxController {
  late final player = Player();
  late final videoController = VideoController(player);
  String url;

  VideoPlayerLogic({required this.url});

  /// 长按倍速播放
  double get fastForwardRate => 3;
  bool fastForwarding = false;

  /// 左右拖动进度
  double totalDx = 0; // 左右滑动过程中累计的dx
  int destSeconds = 0; // 最终要跳转的描述
  String willSeekPosition = ''; // 拖动时展示的文字
  bool willSeekPositionIsFuture = false;

  /// 截图
  File? screenShotFile; // 截图文件
  bool capturing = false;

  @override
  void onInit() {
    super.onInit();
    player.open(Media(url));
  }

  @override
  void onClose() {
    player.dispose();
    super.onClose();
  }

  /// 添加tag来支持通过从系列进入到其他动漫来打开多个视频播放页
  static String generateTag(String url) {
    return 'video-url-$url';
  }

  longPressToSpeedUp() {
    if (!player.state.playing) return;

    player.setRate(fastForwardRate);
    fastForwarding = true;
    update();
  }

  cancelSpeedUp() {
    player.setRate(1);
    fastForwarding = false;
    update();
  }

  calculateWillSeekPosition(double dx) {
    totalDx += dx;
    // 根据最终位移，计算出快进/后退的秒数
    int secondsGap = totalDx.abs() ~/ 5;
    // 获取当前视频播放的进度秒数
    int curSeconds = player.state.position.inSeconds;
    // 要跳转的进度秒数
    destSeconds = curSeconds;
    // 最小偏移，偏移过小时不改变进度，避免和调整亮度和音量冲突
    var minOffset = 5;

    if (totalDx > 0 + minOffset) {
      destSeconds += secondsGap;
      // 如果快进到最大秒数，则修正为最大秒数
      if (destSeconds > player.state.duration.inSeconds) {
        destSeconds = player.state.duration.inSeconds;
      }

      willSeekPositionIsFuture = true;
      willSeekPosition =
          "${TimeUtil.getReadableDuration(Duration(seconds: destSeconds))} | + ${TimeUtil.getReadableDuration(Duration(seconds: secondsGap))}";
    } else if (totalDx < 0 - minOffset) {
      destSeconds -= secondsGap;
      // 如果后退至开头，则修正为0
      if (destSeconds < 0) destSeconds = 0;

      willSeekPositionIsFuture = false;
      willSeekPosition =
          "${TimeUtil.getReadableDuration(Duration(seconds: destSeconds))} | - ${TimeUtil.getReadableDuration(Duration(seconds: secondsGap))}";
    }
    update();
  }

  seekDragEndPosition() async {
    // 寻找并播放
    await player.seek(Duration(seconds: destSeconds));
    player.play();
    // 重置
    totalDx = 0;
    destSeconds = 0;
    willSeekPosition = '';
    update();
  }

  /// 切换桌面端全屏
  toggleDesktopFullscreen({
    void Function(bool isFullScreen)? whenDesktopToggleFullScreen,
  }) async {
    bool isFullScreen = await windowManager.isFullScreen();
    bool willFullScreen = !isFullScreen;
    whenDesktopToggleFullScreen?.call(willFullScreen);

    await windowManager.setFullScreen(!isFullScreen);
    isFullScreen = await windowManager.isFullScreen();
    if (!isFullScreen) {
      // 不是全屏时，重新设置宽高。因为全屏后退出全屏会导致无法展示当前页的所有信息
      var size = await windowManager.getSize();
      await windowManager.setSize(Size(size.width, size.height - 0.1));
      windowManager.setSize(Size(size.width, size.height));
    }
  }

  capture() async {
    void _handleError(String msg) {
      ToastUtil.showText(msg);
      capturing = false;
      update();
    }

    player.pause();
    capturing = true;
    update();

    late Uint8List? uint8list;
    try {
      uint8list = await player.screenshot();
    } catch (e) {
      _handleError("截图出错：$e");
      return;
    }

    if (uint8list == null) {
      _handleError("截图失败");
      return;
    }

    String? rootPath;
    File? file;
    String fileName = "Capture_${TimeUtil.getNowString2()}.jpg";

    if (PlatformUtil.isDesktop) {
      rootPath = (await getDownloadsDirectory())?.path;
      if (rootPath == null) {
        return _handleError("无法获取到保存路径");
      }

      file = File(p.join(rootPath, '漫迹', fileName));
    } else if (Platform.isAndroid) {
      rootPath = await FileUtil.getExternalDirPath();
      if (rootPath == null) {
        return _handleError("无法获取到保存路径");
      }

      if (Platform.isAndroid) {
        bool? isGranted =
            await PermissionUtil.requestManageExternalStorage(onlyCheck: true);
        if (isGranted == false) {
          isGranted = await Get.dialog(AlertDialog(
            title: const Text('提示'),
            content: const Text('保存文件需要您授予文件管理权限，是否前往设置？'),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('取消')),
              TextButton(
                  onPressed: () async {
                    bool isGranted =
                        await PermissionUtil.requestManageExternalStorage();
                    Get.back(result: isGranted);
                  },
                  child: const Text('前往设置')),
            ],
          ));
        }
        if (isGranted != true) {
          return _handleError("没有权限写入文件");
        }
      }

      // 如果设置了笔记图片路径，则保存到该位置下
      final noteImageRootDirPath = ImageUtil.noteImageRootDirPath;
      if (noteImageRootDirPath.isNotEmpty) {
        file = File(p.join(noteImageRootDirPath, fileName));
      } else {
        file = File(p.join(rootPath, 'Pictures', '漫迹', fileName));
      }
    }

    if (file == null) {
      return _handleError("无法获取到保存文件");
    }

    // 图片保存到文件中
    if (await file.exists()) {
      return _handleError("文件 ${p.basename(file.path)} 已存在");
    }

    try {
      await file.create(recursive: true);
      await file.writeAsBytes(uint8list);
    } catch (e) {
      return _handleError("写入文件错误");
    }

    if (!(await file.exists())) {
      return _handleError("写入文件失败");
    }

    Log.info('caputre file：${file.path}');

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
}
