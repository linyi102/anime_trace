import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'sp_util.dart';

/// 记录和修改shared_preferences的值
class SpProfile {
  static int getGridColumnCnt() {
    return SPUtil.getInt("gridColumnCnt",
        defaultValue: Platform.isWindows ? 6 : 3);
  }

  static Future<bool> setWindowSize(Size size) async {
    debugPrint("修改窗口大小：$size");
    await SPUtil.setDouble("WindowWidth", size.width);
    await SPUtil.setDouble("WindowHeight", size.height);
    return true;
  }

  // 1280*720
  // 1024*720
  // 900*600
  static getWindowWidth() {
    return SPUtil.getDouble("WindowWidth", defaultValue: 1024);
  }

  static getWindowHeight() {
    return SPUtil.getDouble("WindowHeight", defaultValue: 720);
  }

  //  Windows侧边栏展开或收缩
  static getExpandSideBar() {
    return SPUtil.getBool("expandSideBar", defaultValue: false);
  }

  static setCoverBgSigmaInAnimeDetailPage(double sigma) {
    SPUtil.setDouble("coverBgSigmaInAnimeDetailPage", sigma);
  }

  static getCoverBgSigmaInAnimeDetailPage() {
    return SPUtil.getDouble("coverBgSigmaInAnimeDetailPage",
        defaultValue: 10.0);
  }
}
