import 'package:flutter_test_future/utils/time_util.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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

    if (totalDx > 0) {
      destSeconds += secondsGap;
      // 如果快进到最大秒数，则修正为最大秒数
      if (destSeconds > player.state.duration.inSeconds) {
        destSeconds = player.state.duration.inSeconds;
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
    await player.seek(Duration(seconds: destSeconds));
    player.play();
    // 重置
    totalDx = 0;
    destSeconds = 0;
    willSeekPosition = '';
    update();
  }
}
