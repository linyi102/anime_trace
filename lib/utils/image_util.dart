import 'dart:io';

import 'package:flutter/cupertino.dart';
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

  // win没有缓存，可以直接得到完整路径：
  // absoluteImagePath=D:\Syfolder\pictures\动漫截图\封面\8d5494eef01f3a292df59aa89a6eab315c6034a8d608.jpg
  // mumu模拟器：
  // absoluteImagePath=/data/user/0/com.example.flutter_test_future/cache/file_picker/2c9d072bd73e8b4bfd629a6a17484e38.png
  // 可以看到，选择的图片会存放到缓存目录中，和设定的根目录无关，直接删除/cache/file_picker以及前面的字符串就好
  // TODO 如果根目录设置的是 "/动漫截图"，而封面是放在 "/动漫截图/封面" 下，而数据库中保存的是图片名称，此时根目录+动漫名字，缺少了一级目录 "/封面"
  static String getRelativeCoverImagePath(String absoluteImagePath) {
    // 绝对路径去掉根路径的长度，就是相对路径
    debugPrint("absoluteImagePath=$absoluteImagePath");
    String relativeImagePath =
        absoluteImagePath.substring(ImageUtil.coverImageRootDirPath.length);
    debugPrint("根路径ImageUtil.coverImageRootDirPath=${ImageUtil.coverImageRootDirPath}");
    relativeImagePath = _removeCachePrefix(relativeImagePath);
    return relativeImagePath;
  }

  static String getRelativeNoteImagePath(String absoluteImagePath) {
    // 绝对路径去掉根路径的长度，就是相对路径
    String relativeImagePath =
        absoluteImagePath.substring(ImageUtil.noteImageRootDirPath.length);
    // debugPrint("relativeImagePath: $relativeImagePath");
    relativeImagePath = _removeCachePrefix(relativeImagePath);
    // debugPrint("relativeImagePath: $relativeImagePath");
    return relativeImagePath;
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

  static String _removeCachePrefix(String path) {
    // 对于Android，会有缓存，因此文件名是test_future/cache/file_picker/Screenshot...，需要删除
    debugPrint("去掉根路径后，relativeImagePath: $path");
    String cacheNameStr = "test_future/cache/file_picker";
    if (Platform.isAndroid && path.startsWith(cacheNameStr)) {
      path = path.substring(cacheNameStr.length);
    }
    // MuMu模拟器
    cacheNameStr = "st_future/cache/file_picker";
    if (Platform.isAndroid && path.startsWith(cacheNameStr)) {
      path = path.substring(cacheNameStr.length);
    }
    debugPrint("去除缓存路径后，relativeImagePath: $path");
    return path;
  }

  static String _fixPathSeparator(String path) {
    // debugPrint("修复前，路径为$path");
    path = path.replaceAll("/", separator);
    path = path.replaceAll("\\", separator);
    // debugPrint("修复后，路径为$path");
    return path;
  }
}
