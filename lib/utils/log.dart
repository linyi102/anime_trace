import 'dart:async';
import 'dart:io';

import 'package:animetrace/utils/windows.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

class AppLog {
  static final _logOutPut = _LogOutPut(maxLines: 1500);

  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      colors: true,
      printEmojis: true,
      noBoxingByDefault: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
    filter: ProductionFilter(),
    output: _logOutPut,
    level: kDebugMode ? Level.trace : Level.info,
  );

  static void debug(dynamic message) {
    _logger.d(message);
  }

  static void info(dynamic message) {
    _logger.i(message);
  }

  static void warn(dynamic message) {
    _logger.w(message);
  }

  static void error(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void share() async {
    final dir = await getTemporaryDirectory();
    final file = await File(p.join(
            dir.path, 'manji_log_${DateTime.now().millisecondsSinceEpoch}.txt'))
        .create();
    await file.writeAsString(_logOutPut.records.join('\n'));
    if (Platform.isWindows) {
      WindowsUtil.locateFile(file.path);
    } else {
      Share.shareXFiles([XFile(file.path)]).then((_) => file.delete());
    }
  }
}

class _LogOutPut extends LogOutput {
  List<String> records = [];
  final int maxLines;

  _LogOutPut({this.maxLines = 1500});

  final _ansiEscape = RegExp(r'\x1B\[[0-9;]*m');

  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      debugPrint(line);
      // 移除彩色ANSI码
      records.add(line.replaceAll(_ansiEscape, ''));
      if (records.length > maxLines) {
        records = records.sublist(maxLines ~/ 3);
      }
    }
  }
}

R? runZonedGuardedWithLog<R>(
  R Function() body, {
  bool printToConsole = true,
  Map<Object?, Object?>? zoneValues,
  ZoneSpecification? zoneSpecification,
}) {
  FlutterError.onError = (details) {
    AppLog.error('Flutter Error',
        error: details.exception, stackTrace: details.stack);
  };
  PlatformDispatcher.instance.onError = (err, stack) {
    AppLog.error('PlatformDispatcher Error', error: err, stackTrace: stack);
    return true;
  };
  return runZonedGuarded(
    body,
    (error, stack) {
      AppLog.error('Zone Error', error: error, stackTrace: stack);
    },
    zoneValues: zoneValues,
    zoneSpecification: zoneSpecification,
  );
}
