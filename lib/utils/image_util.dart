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
    debugPrint("绝对路径absoluteImagePath=$absoluteImagePath");
    String relativeImagePath = _removeRootDirPath(absoluteImagePath, ImageUtil.coverImageRootDirPath);
    debugPrint("图片根路径ImageUtil.coverImageRootDirPath=${ImageUtil.coverImageRootDirPath}");
    debugPrint("去除图片根路径后，relativeImagePath: $relativeImagePath");
    relativeImagePath = _removeCachePrefix(relativeImagePath);
    return relativeImagePath;
  }

  static String getRelativeNoteImagePath(String absoluteImagePath) {
    // 绝对路径去掉根目录的长度，就是相对路径。
    // 修正：Android端选择的图片路径在缓存目录，因此没有设置的根目录，不能去掉根目录的长度，而是进行替换
    // String relativeImagePath =
    //     absoluteImagePath.substring(ImageUtil.noteImageRootDirPath.length);
    String relativeImagePath = _removeRootDirPath(absoluteImagePath, ImageUtil.noteImageRootDirPath);
    // debugPrint("relativeImagePath: $relativeImagePath");
    relativeImagePath = _removeCachePrefix(relativeImagePath);
    // debugPrint("relativeImagePath: $relativeImagePath");
    return relativeImagePath;
  }

  static String _removeRootDirPath(String path, String rootDirPath) {
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

  static String _removeCachePrefix(String path) {
    // 对于Android，会把选中的图片都缓存在一级目录/data/user/0/com.example.flutter_test_future/cache/file_picker下
    // 因此找到/cache/file_picker并删除该字符串在内的前面所有字符串
    if (Platform.isAndroid) {
      String patternStr = "/cache/file_picker";
      int validIndex = path.indexOf(patternStr) + patternStr.length;
      path = path.substring(validIndex); // 获取validIndex开始的字符串
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
