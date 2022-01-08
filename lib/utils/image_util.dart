import 'dart:io';

import 'package:flutter_test_future/utils/sp_util.dart';

class ImageUtil {
  static ImageUtil? _instance;
  ImageUtil._();
  static late String imageRootDirPath;

  static getInstance() async {
    if (Platform.isAndroid) {
      imageRootDirPath =
          SPUtil.getString("imageAndroidRootDirPath", defaultValue: "");
    } else if (Platform.isWindows) {
      imageRootDirPath =
          SPUtil.getString("imageWindowsRootDirPath", defaultValue: "");
    } else {
      throw ("未适配平台：${Platform.operatingSystem}");
    }
    return _instance ?? ImageUtil._();
  }

  static String setImageRootDirPath(String imageRootDirPath) {
    if (Platform.isAndroid) {
      SPUtil.setString("imageAndroidRootDirPath", imageRootDirPath);
    } else if (Platform.isWindows) {
      SPUtil.setString("imageWindowsRootDirPath", imageRootDirPath);
    } else {
      throw ("未适配平台：${Platform.operatingSystem}");
    }
    ImageUtil.imageRootDirPath = imageRootDirPath; // 记得更新这个
    return imageRootDirPath;
  }

  static bool hasImageRootDirPath() {
    return ImageUtil.imageRootDirPath.isNotEmpty;
  }

  static String getRelativeImagePath(String absoluteImagePath) {
    // 绝对路径去掉根路径的长度，就是相对路径
    String relativeImagePath =
        absoluteImagePath.substring(ImageUtil.imageRootDirPath.length);
    // debugPrint("relativeImagePath: $relativeImagePath");
    // 对于Android，会有缓存，因此文件名是test_future/cache/file_picker/Screenshot...，需要删除
    String cacheNameStr = "test_future/cache/file_picker";
    if (Platform.isAndroid && relativeImagePath.startsWith(cacheNameStr)) {
      relativeImagePath = relativeImagePath.substring(cacheNameStr.length);
    }
    // debugPrint("relativeImagePath: $relativeImagePath");
    return relativeImagePath;
  }

  static String getAbsoluteImagePath(String relativeImagePath) {
    return imageRootDirPath + relativeImagePath;
  }
}
