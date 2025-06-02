import 'package:flutter/foundation.dart';
import 'package:flutter_logkit/logkit.dart';

final logger = LogkitLogger(
  logkitSettings: const LogkitSettings(
    disableAttachOverlay: kReleaseMode,
    disableRecordLog: false,
    maxLogCount: 500,
    printToConsole: true,
    printTime: true,
  ),
);

class Log {
  static void build<T>(Type runtimeType) {
    logger.info('build widget', tag: runtimeType.toString());
  }

  static void info<T>(T content, {Type? runTimeType}) {
    logger.info(content.toString(), tag: runTimeType?.toString());
  }

  static void debug<T>(T content) {
    logger.debug(content.toString());
  }

  static void warn<T>(T content) {
    logger.warning(content.toString());
  }

  static void error<T>(T content) {
    logger.error(content.toString());
  }
}
