import 'package:flutter/foundation.dart';

class Log {
  static void build<T>(Type runtimeType) {
    if (kDebugMode) {
      info("$runtimeType: build");
    }
  }

  static void info<T>(T content, {Type? runTimeType}) {
    if (kDebugMode) {
      String typeStr = runTimeType == null ? "" : ":${runTimeType.toString()}";
      debugPrint(
          '🟩[INFO$typeStr][${DateTime.now().toString().substring(5)}]$content🟩');
    }
  }

  static void debug<T>(T content) {
    if (kDebugMode) {
      debugPrint(
          '🟦[DEBUG][${DateTime.now().toString().substring(5)}]$content🟦');
    }
  }

  static void warn<T>(T content) {
    if (kDebugMode) {
      debugPrint(
          '🟨[WARN][${DateTime.now().toString().substring(5)}]$content🟨');
    }
  }

  static void error<T>(T content) {
    if (kDebugMode) {
      debugPrint(
          '🟥[ERROR][${DateTime.now().toString().substring(5)}]$content🟥');
    }
  }
}
