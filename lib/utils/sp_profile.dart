import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'sp_util.dart';

class SpProfile {
  static getGridColumnCnt() {
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
  // 900*600
  static getWindowWidth() {
    return SPUtil.getDouble("WindowWidth", defaultValue: 900);
  }

  static getWindowHeight() {
    return SPUtil.getDouble("WindowHeight", defaultValue: 600);
  }
}
