import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerLogic extends GetxController {
  late final player = Player();
  late final videoController = VideoController(player);
  String url;

  VideoPlayerLogic({required this.url});

  double get fastForwardRate => 3;
  bool fastForwarding = false;

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
}
