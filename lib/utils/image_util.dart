import 'dart:io';

import 'package:animetrace/utils/sp_util.dart';
import 'package:path/path.dart';
import 'package:animetrace/utils/log.dart';

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
    } else if (Platform.isIOS) {
      noteImageRootDirPath = '';
      coverImageRootDirPath = '';
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
    } else if (Platform.isIOS) {
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
    } else if (Platform.isIOS) {
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

  static String getRelativeCoverImagePath(String absoluteImagePath) {
    // 绝对路径去掉根路径的长度，就是相对路径
    Log.info("绝对路径absoluteImagePath=$absoluteImagePath");
    String relativeImagePath =
        _removeRootDirPath(absoluteImagePath, ImageUtil.coverImageRootDirPath);
    Log.info(
        "图片根路径ImageUtil.coverImageRootDirPath=${ImageUtil.coverImageRootDirPath}");
    Log.info("去除图片根路径后，relativeImagePath: $relativeImagePath");
    return relativeImagePath;
  }

  static String getRelativeNoteImagePath(String absoluteImagePath) {
    // 绝对路径去掉根目录的长度，就是相对路径
    String relativeImagePath =
        _removeRootDirPath(absoluteImagePath, ImageUtil.noteImageRootDirPath);
    return relativeImagePath;
  }

  static String _removeRootDirPath(String path, String rootDirPath) {
    String relativeImagePath = path;
    // Android选择图片后会缓存在/data/user/<package_name>/cache/file_picker/目录下
    final cacheNameRegExp = RegExp(r'^\/data\/user.*\/cache\/file_picker');
    if (Platform.isAndroid && relativeImagePath.contains(cacheNameRegExp)) {
      return relativeImagePath.replaceFirst(cacheNameRegExp, '');
    }
    return path.replaceFirst(rootDirPath, "");
  }

  static String getAbsoluteNoteImagePath(String relativeImagePath) {
    String absolutePath = noteImageRootDirPath + relativeImagePath;
    absolutePath = _fixPathSeparator(absolutePath);
    return absolutePath;
  }

  static String getAbsoluteCoverImagePath(String relativeImagePath) {
    String absolutePath = coverImageRootDirPath + relativeImagePath;
    absolutePath = _fixPathSeparator(absolutePath);
    return absolutePath;
  }

  static String _fixPathSeparator(String path) {
    // Log.info("修复前，路径为$path");
    path = path.replaceAll("/", separator);
    path = path.replaceAll("\\", separator);
    // Log.info("修复后，路径为$path");
    return path;
  }
}
