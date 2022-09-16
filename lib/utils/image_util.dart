import 'dart:io';

import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:path/path.dart';

class ImageUtil {
  static ImageUtil? _instance;

  ImageUtil._();

  static late String noteImageRootDirPath;
  static late String coverImageRootDirPath;
  static const String noteImageRootDirPathKeyInAndroid =
      "imageAndroidRootDirPath";
  static const String noteImageRootDirPathKeyInWindows =
      "imageWindowsRootDirPath";
  static const String coverImageRootDirPathKeyInAndroid =
      "coverImageAndroidRootDirPath";
  static const String coverImageRootDirPathKeyInWindows =
      "coverImageWindowsRootDirPath";

  static getInstance() async {
    if (Platform.isAndroid) {
      noteImageRootDirPath =
          SPUtil.getString(noteImageRootDirPathKeyInAndroid, defaultValue: "");
      coverImageRootDirPath =
          SPUtil.getString(coverImageRootDirPathKeyInAndroid, defaultValue: "");
    } else if (Platform.isWindows) {
      noteImageRootDirPath =
          SPUtil.getString(noteImageRootDirPathKeyInWindows, defaultValue: "");
      coverImageRootDirPath =
          SPUtil.getString(coverImageRootDirPathKeyInWindows, defaultValue: "");
    } else {
      throw ("未适配平台：${Platform.operatingSystem}");
    }
    return _instance ?? ImageUtil._();
  }

  static void setNoteImageRootDirPath(String imageRootDirPath) {
    if (Platform.isAndroid) {
      SPUtil.setString(noteImageRootDirPathKeyInAndroid, imageRootDirPath);
    } else if (Platform.isWindows) {
      SPUtil.setString(noteImageRootDirPathKeyInWindows, imageRootDirPath);
    } else {
      throw ("未适配平台：${Platform.operatingSystem}");
    }
    ImageUtil.noteImageRootDirPath = imageRootDirPath; // 记得更新这个
  }

  static void setCoverImageRootDirPath(String imageRootDirPath) {
    if (Platform.isAndroid) {
      SPUtil.setString(coverImageRootDirPathKeyInAndroid, imageRootDirPath);
    } else if (Platform.isWindows) {
      SPUtil.setString(coverImageRootDirPathKeyInWindows, imageRootDirPath);
    } else {
      throw ("未适配平台：${Platform.operatingSystem}");
    }
    ImageUtil.coverImageRootDirPath = imageRootDirPath; // 记得更新这个
  }

  static bool hasNoteImageRootDirPath() {
    return ImageUtil.noteImageRootDirPath.isNotEmpty;
  }

  static bool hasCoverImageRootDirPath() {
    return ImageUtil.coverImageRootDirPath.isNotEmpty;
  }

  static String getRelativeImagePath(String absoluteImagePath) {
    // 绝对路径去掉根路径的长度，就是相对路径
    String relativeImagePath =
        absoluteImagePath.substring(ImageUtil.noteImageRootDirPath.length);
    // debugPrint("relativeImagePath: $relativeImagePath");
    // 对于Android，会有缓存，因此文件名是test_future/cache/file_picker/Screenshot...，需要删除
    String cacheNameStr = "test_future/cache/file_picker";
    if (Platform.isAndroid && relativeImagePath.startsWith(cacheNameStr)) {
      relativeImagePath = relativeImagePath.substring(cacheNameStr.length);
    }
    // MuMu模拟器
    cacheNameStr = "st_future/cache/file_picker";
    if (Platform.isAndroid && relativeImagePath.startsWith(cacheNameStr)) {
      relativeImagePath = relativeImagePath.substring(cacheNameStr.length);
    }
    // debugPrint("relativeImagePath: $relativeImagePath");
    return relativeImagePath;
  }

  static String getAbsoluteNoteImagePath(String relativeImagePath) {
    String absolutePath = noteImageRootDirPath + relativeImagePath;
    // debugPrint("修复前，路径为$absolutePath");
    absolutePath = absolutePath.replaceAll("/", separator);
    absolutePath = absolutePath.replaceAll("\\", separator);
    // debugPrint("修复后，路径为$absolutePath");
    return absolutePath;
  }

  static String getAbsoluteCoverImagePath(String relativeImagePath) {
    String absolutePath = coverImageRootDirPath + relativeImagePath;
    // debugPrint("修复前，路径为$absolutePath");
    absolutePath = absolutePath.replaceAll("/", separator);
    absolutePath = absolutePath.replaceAll("\\", separator);
    // debugPrint("修复后，路径为$absolutePath");
    return absolutePath;
  }
}
