import 'dart:math';

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
}
