import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/models/page_switch_animation.dart';
import 'package:flutter_test_future/utils/log.dart';

import 'sp_util.dart';

/// 记录和修改shared_preferences的值
class SpProfile {
  // 选择的路由动画
  static void savePageSwitchAnimationId(int id) {
    // 不能将其转为map后保存，因为后期可能会修改名称，所以保存不会变化的id
    SPUtil.setInt("selectedPageSwitchAnimationId", id);
  }

  // 获取页面切换动画小哥哥
  static PageSwitchAnimation getPageSwitchAnimation() {
    final defaultVal = Platform.isWindows
        ? PageSwitchAnimation.fade
        : PageSwitchAnimation.cupertino;

    // 返回用户选择的效果
    int id = SPUtil.getInt("selectedPageSwitchAnimationId",
        defaultValue: defaultVal.id);
    for (var e in PageSwitchAnimation.values) {
      if (e.id == id) {
        return e;
      }
    }

    // 如果记录的id找不到，则使用默认效果
    return defaultVal;
  }

  // 设置动漫网格列数
  static int getGridColumnCnt() {
    return SPUtil.getInt("gridColumnCnt",
        defaultValue: Platform.isWindows ? 6 : 3);
  }

  // 窗口大小
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
  static double getWindowWidth() {
    double defaultValue = 1024.0;
    if (Global.isRelease) {
      return SPUtil.getDouble("WindowWidth", defaultValue: defaultValue);
    }
    return 1024.0;
  }

  static double getWindowHeight() {
    double defaultValue = 720.0;
    if (Global.isRelease) {
      return SPUtil.getDouble("WindowHeight", defaultValue: defaultValue);
    }
    return 720.0;
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
    return SPUtil.getDouble("coverBgHeightRatio", defaultValue: 0.4);
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
    SPUtil.setBool("enableParallaxInAnimeDetailPage",
        !getEnableParallaxInAnimeDetailPage());
  }

  static bool getEnableParallaxInAnimeDetailPage() {
    return SPUtil.getBool("enableParallaxInAnimeDetailPage",
        defaultValue: false);
  }

  // 笔记页中显示/隐藏所有图片
  static setShowAllNoteGridImage(bool show) {
    SPUtil.setBool("showAllNoteGridImage", show);
  }

  static getShowAllNoteGridImage() {
    return SPUtil.getBool("showAllNoteGridImage", defaultValue: false);
  }

  // 开启/关闭多选标签查询
  static turnEnableMultiLabelQuery() {
    SPUtil.setBool("enableMultiLabelQuery", !getEnableMultiLabelQuery());
  }

  static bool getEnableMultiLabelQuery() {
    return SPUtil.getBool("enableMultiLabelQuery", defaultValue: true);
  }
}
