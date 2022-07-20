import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'sp_util.dart';

class SpProfile {
  static getGridColumnCnt() {
    return SPUtil.getInt("gridColumnCnt",
        defaultValue: Platform.isWindows ? 8 : 3);
  }

  static Future<bool> setWindowSize(Size size) async {
    debugPrint("修改窗口大小：$size");
    await SPUtil.setDouble("WindowWidth", size.width);
    await SPUtil.setDouble("WindowHeight", size.height);
    return true;
  }

  static getWindowWidth() {
    return SPUtil.getDouble("WindowWidth", defaultValue: 1200);
  }

  static getWindowHeight() {
    return SPUtil.getDouble("WindowHeight", defaultValue: 720);
  }
}
