import 'dart:io';

class PlatformUtil {
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  // Windows、Linux、macOS、fuchsia、Web
  static bool get isDesktop => !isMobile;

  static Duration? get tabControllerAnimationDuration =>
      isMobile ? null : Duration.zero;
}
