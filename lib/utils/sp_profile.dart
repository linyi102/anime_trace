import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test_future/utils/log.dart';

import 'sp_util.dart';

/// 记录和修改shared_preferences的值
class SpProfile {
  static int getGridColumnCnt() {
    return SPUtil.getInt("gridColumnCnt",
        defaultValue: Platform.isWindows ? 6 : 3);
  }

  static Future<bool> setWindowSize(Size size) async {
    Log.info("修改窗口大小：$size");
    await SPUtil.setDouble("WindowWidth", size.width);
    await SPUtil.setDouble("WindowHeight", size.height);
    return true;
  }

  // 记得修改刚开始启动的窗口大小
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

  // 设置模糊伽马值
  static setCoverBgSigmaInAnimeDetailPage(double sigma) {
    SPUtil.setDouble("coverBgSigmaInAnimeDetailPage", sigma);
  }

  // 默认的模糊伽马值为10
  static getCoverBgSigmaInAnimeDetailPage() {
    return SPUtil.getDouble("coverBgSigmaInAnimeDetailPage", defaultValue: 0.0);
  }

  // 设置是否渐变
  static turnEnableCoverBgGradient() {
    SPUtil.setBool("enableCoverBgGradient", !getEnableCoverBgGradient());
  }

  static bool getEnableCoverBgGradient() {
    return SPUtil.getBool("enableCoverBgGradient", defaultValue: true);
  }

  // 记录封面背景高度占屏幕高度的比例
  static void setCoverBgHeightRatio(double value) {
    SPUtil.setDouble("coverBgHeightRatio", value);
  }

  static double getCoverBgHeightRatio() {
    return SPUtil.getDouble("coverBgHeightRatio", defaultValue: 0.3);
  }

  // 动漫详细页显示/因此简介
  static turnShowDescInAnimeDetailPage() {
    SPUtil.setBool(
        "showDescInAnimeDetailPage", !getShowDescInAnimeDetailPage());
  }

  static bool getShowDescInAnimeDetailPage() {
    return SPUtil.getBool("showDescInAnimeDetailPage", defaultValue: true);
  }

  // 动漫详细页下滑时背景封面添加视差效果
  static turnEnableParallaxInAnimeDetailPage() {
    SPUtil.setBool(
        "enableParallaxInAnimeDetailPage", !getEnableParallaxInAnimeDetailPage());
  }

  static bool getEnableParallaxInAnimeDetailPage() {
    return SPUtil.getBool("enableParallaxInAnimeDetailPage", defaultValue: false);
  }

  // 笔记页中显示/隐藏所有图片
  static setShowAllNoteGridImage(bool show) {
    SPUtil.setBool("showAllNoteGridImage", show);
  }

  static getShowAllNoteGridImage() {
    return SPUtil.getBool("showAllNoteGridImage", defaultValue: false);
  }
}
