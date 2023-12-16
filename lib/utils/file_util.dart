import 'dart:io';
import 'dart:math';

import 'package:flutter_test_future/utils/log.dart';
import 'package:path_provider/path_provider.dart';

class FileUtil {
  /// 根据传入的字节数，转为可读的文件大小
  static String getReadableFileSize(int size) {
    int kb = 1024, mb = 1048576, gb = 1073741824;
    if (size < kb) {
      return "${size}B";
    } else if (size < mb) {
      return "${(size / kb).toStringAsFixed(2)}KB";
    } else if (size < gb) {
      return "${(size / mb).toStringAsFixed(2)}MB";
    } else {
      return "${(size / gb).toStringAsFixed(2)}GB";
    }
  }

  // Format File Size
  // 来源：https://stackoverflow.com/questions/68110965/how-to-display-the-image-file-size-taken-from-flutter-image-picker-plugin
  static String getFileSizeString({required int bytes, int decimals = 0}) {
    if (bytes <= 0) return "0 Bytes";
    const suffixes = [" Bytes", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + suffixes[i];
  }

  /// 获取安卓外部存储根目录
  static Future<String?> getExternalDirPath() async {
    Directory? dir = await getExternalStorageDirectory();
    if (dir == null) return null;
    Log.info('externalStorageDirectory.path=${dir.path}');

    String externalPath =
        dir.path.replaceFirst(RegExp('/Android/data/.*/files'), '');
    Log.info('externalPath=$externalPath');
    return externalPath;
  }
}
