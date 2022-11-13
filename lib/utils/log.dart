import 'package:flutter/foundation.dart';

/// 来源：[Dart Log工具类-kicinio的博客-CSDN博客-dart log](https://blog.csdn.net/kicinio/article/details/125950014)
class Log {
  static void info<T>(T content) {
    DateTime date = DateTime.now();
    if (kDebugMode) {
      debugPrint(
          '🟩 [INFO] [${date.hour}:${date.minute}:${date.second}:${date.millisecond}] $content 🟩');
    }
  }

  static void debug<T>(T content) {
    DateTime date = DateTime.now();
    if (kDebugMode) {
      debugPrint(
          '🟦 [DEBUG] [${date.hour}:${date.minute}:${date.second}:${date.millisecond}] $content 🟦');
    }
  }

  static void warn<T>(T content) {
    DateTime date = DateTime.now();
    if (kDebugMode) {
      debugPrint(
          '🟨 [WARN] [${date.hour}:${date.minute}:${date.second}:${date.millisecond}] $content 🟨');
    }
  }

  static void error<T>(T content) {
    DateTime date = DateTime.now();
    if (kDebugMode) {
      debugPrint(
          '🟥 [ERROR] ${date.hour}:${date.minute}:${date.second}:${date.millisecond} || $content 🟥');
    }
  }
}
