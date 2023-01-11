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
}
