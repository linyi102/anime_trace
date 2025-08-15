import 'dart:io';

import 'package:flutter/material.dart';

class PlatformUtil {
  static bool get isMobile => Platform.isAndroid || Platform.isIOS || Platform.isOhos;

  /// Windows、Linux、macOS、fuchsia、Web
  static bool get isDesktop => !isMobile;

  /// 点击tab栏切换时的动画时长
  static Duration get tabControllerAnimationDuration => kTabScrollDuration;

  /// 左右滑动切换tab栏
  static ScrollPhysics? get tabBarViewPhysics =>
      isMobile ? null : const NeverScrollableScrollPhysics();
}
