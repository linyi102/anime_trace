import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:get/get.dart';

class ThemeColor {
  bool isDarkMode;
  String key;
  String name;
  Color primaryColor; // 代表色
  Color appBarColor; // 顶部栏颜色。用于顶部栏、底部栏、侧边栏
  Color bodyColor; // 主体颜色。最底的背景
  Color cardColor; // 卡片颜色。用于卡片、对话框

  ThemeColor(
      {required this.isDarkMode,
      required this.key,
      required this.name,
      required this.primaryColor,
      required this.appBarColor,
      required this.bodyColor,
      required this.cardColor});

  @override
  String toString() {
    return 'ThemeColor{isDarkMode: $isDarkMode, name: $name, primaryColor: $primaryColor, appBarColor: $appBarColor, bodyColor: $bodyColor, cardColor: $cardColor}';
  }
}

class ThemeUtil {
  static final ThemeController themeController = Get.find();
  static const smallScaleFactor = 0.9;
  static const tinyScaleFactor = 0.8;

  static Map<String, ThemeColor> themeColors = {
    "white": ThemeColor(
        isDarkMode: false,
        key: "white",
        name: "白色",
        primaryColor: const Color.fromRGBO(248, 248, 248, 1),
        appBarColor: Colors.white,
        bodyColor: const Color.fromRGBO(248, 248, 248, 1),
        cardColor: Colors.white),
    "black": ThemeColor(
        isDarkMode: true,
        key: "black",
        name: "黑色",
        primaryColor: Colors.black,
        appBarColor: const Color.fromRGBO(48, 48, 48, 1),
        bodyColor: const Color.fromRGBO(43, 43, 43, 1),
        cardColor: const Color.fromRGBO(48, 48, 48, 1)),
    "nightBlue": ThemeColor(
        isDarkMode: true,
        key: "nightBlue",
        name: "夜蓝",
        primaryColor: const Color.fromRGBO(12, 19, 35, 1),
        appBarColor: const Color.fromRGBO(8, 9, 27, 1),
        bodyColor: const Color.fromRGBO(12, 19, 35, 1),
        cardColor: const Color.fromRGBO(24, 25, 43, 1))
  };

  // 主题色
  static Color getThemePrimaryColor() {
    Color color = Colors.blue;
    // color = const Color.fromRGBO(0, 206, 209, 1); // 深绿宝石
    // color = const Color.fromRGBO(82, 82, 136, 1); // 野菊紫
    // color = const Color.fromRGBO(239, 71, 93, 1); // 草茉莉红
    // color = const Color.fromRGBO(255, 127, 80, 1); // 珊瑚
    // color = const Color.fromRGBO(32, 178, 170, 1); // 浅海洋绿
    // color = const Color.fromRGBO(192, 72, 81, 1); // 玉红
    // color = Colors.amber;
    // color = Colors.lightBlue;
    // color = const Color.fromRGBO(86, 152, 195, 1); // 睛蓝
    // color = const Color.fromRGBO(0, 191, 255, 1); // 深天蓝
    // color = const Color.fromRGBO(7, 176, 242, 1);
    return color;
  }

  // ListTile>leading按钮颜色
  static Color getLeadingIconColor() {
    return ThemeUtil.getThemePrimaryColor();
  }

  static Color getConnectableColor() {
    return const Color.fromRGBO(8, 241, 117, 1);
  }

  // 顶部栏背景色
  // 目录页中的过滤组件也使用了该颜色
  static Color getAppBarBackgroundColor() {
    return themeController.themeColor.value.appBarColor;
  }

  // 主体背景色
  static Color getScaffoldBackgroundColor() {
    return themeController.themeColor.value.bodyColor;
  }

  // 按钮颜色
  static Color getIconButtonColor() {
    return themeController.themeColor.value.isDarkMode
        ? Colors.white70
        : Colors.black87;
  }

  // 普通字体颜色
  static Color getFontColor() {
    return themeController.themeColor.value.isDarkMode
        ? Colors.white
        : Colors.black87;
  }

  // 目录页中，动漫详细信息(别名、首播时间等)的字体颜色
  static Color getCommentColor() {
    return themeController.themeColor.value.isDarkMode
        ? Colors.white54
        : Colors.black54;
  }

  // 动漫详细页图片背景混合
  static Color getModulateColor() {
    return themeController.themeColor.value.isDarkMode
        ? const Color.fromRGBO(150, 150, 150, 0.9)
        : const Color.fromRGBO(255, 255, 255, 0.9);
  }

  // 动漫详细页图片背景渐变
  static List<Color> getGradientColors() {
    Color color = ThemeUtil.getScaffoldBackgroundColor();
    return [
      // Colors.transparent,
      color.withOpacity(0),
      color.withOpacity(0.1),
      color.withOpacity(0.2),
      color.withOpacity(0.5),
      color.withOpacity(1),
    ];
  }

  // 动漫详细页图片背景渐变下面的遮挡颜色，用于遮挡细线
  static Color getColorBelowGradientAnimeCover() {
    return themeController.themeColor.value.isDarkMode
        ? const Color.fromRGBO(48, 48, 48, 1)
        : const Color.fromRGBO(248, 248, 248, 1);
  }

  // 动漫详细页集ListTile颜色
  static Color getEpisodeListTile(bool isChecked) {
    if (isChecked) {
      return themeController.themeColor.value.isDarkMode
          ? Colors.white38
          : Colors.black54;
    }
    return themeController.themeColor.value.isDarkMode
        ? Colors.white70
        : Colors.black87;
  }

  // 笔记列表页中笔记的背景色
  static Color getCardColor() {
    return themeController.themeColor.value.cardColor;
  }

  static getSideBarBackgroundColor() {
    return getAppBarBackgroundColor();
  }
}
