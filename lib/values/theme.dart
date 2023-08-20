import 'dart:io';

import 'package:flutter/material.dart';

class AppTheme {
  /// 圆角
  static const double cardRadius = 8.0;
  static const double imgRadius = 6.0;
  static const double stateRadius = 4.0; // 集数、观看次数
  static const double bottomSheetRadius = 16.0;
  static const double chipRadius = 40.0;
  static const double timePickerDialogRadius = 16.0;
  static const double dialogRadius = 16.0;
  static const double textButtonRadius = 16.0;

  /// 当前是否是夜间模式
  static bool isDark = false;

  /// wrap间距
  static double get wrapSacing => Platform.isWindows ? 8.0 : 4.0;
  static double get wrapRunSpacing => Platform.isWindows ? 8.0 : 0.0;

  /// 笔记字体样式：动漫详细页里的笔记、评价，以及笔记列表中的笔记，以及笔记编辑页
  static TextStyle noteStyle =
      const TextStyle(height: 1.5, fontSize: 15, fontWeight: FontWeight.normal);

  /// 可连接的颜色
  static Color connectableColor = const Color.fromRGBO(8, 241, 117, 1);

  /// 观看次数的颜色
  static Color reviewNumberBg = Colors.orange;
  static Color reviewNumberFg = Colors.white;

  /// 主题
  static List<ThemeMode> themeModes = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];
  static List<String> darkModes = ["跟随系统", "关闭", "开启"];

  static Color blue = Colors.blue;

  /// 亮色主题
  static List<ThemeColor> lightColors = [
    ThemeColor(
        isDarkMode: false,
        key: "white",
        name: "白色",
        representativeColor: const Color.fromRGBO(248, 248, 248, 1),
        primaryColor: blue,
        appBarColor: Colors.white,
        bodyColor: const Color.fromRGBO(248, 248, 252, 1),
        cardColor: Colors.white),
  ];

  /// 夜间模式主题
  static List<ThemeColor> darkColors = [
    ThemeColor(
      isDarkMode: true,
      key: "lightBlack",
      name: "浅黑",
      primaryColor: blue,
      representativeColor: const Color.fromRGBO(30, 30, 30, 1),
      appBarColor: const Color.fromRGBO(32, 32, 32, 1),
      bodyColor: const Color.fromRGBO(18, 18, 18, 1),
      cardColor: const Color.fromRGBO(30, 30, 30, 1),
    ),
    ThemeColor(
        isDarkMode: true,
        key: "pureBlack",
        name: "纯黑",
        primaryColor: blue,
        representativeColor: Colors.black,
        appBarColor: const Color.fromRGBO(15, 15, 15, 1),
        bodyColor: const Color.fromRGBO(0, 0, 0, 1),
        cardColor: const Color.fromRGBO(15, 15, 15, 1)),
    ThemeColor(
      isDarkMode: true,
      key: "nightPurple",
      name: "夜紫",
      primaryColor: const Color.fromRGBO(90, 106, 213, 1.0),
      representativeColor: const Color.fromRGBO(12, 19, 35, 1),
      appBarColor: const Color.fromRGBO(8, 9, 27, 1),
      bodyColor: const Color.fromRGBO(12, 19, 35, 1),
      // cardColor: const Color.fromRGBO(24, 25, 43, 1),
      cardColor: const Color.fromRGBO(18, 25, 41, 1),
    )
  ];
}

class ThemeColor {
  bool isDarkMode;
  String key;
  String name;
  Color representativeColor; // 代表色
  Color primaryColor; // 主要色。按钮、选中的ListTile颜色
  Color appBarColor; // 顶部栏颜色。用于顶部栏、底部栏、侧边栏
  Color bodyColor; // 主体颜色。最底的背景
  Color cardColor; // 卡片颜色。用于卡片、对话框

  ThemeColor(
      {required this.isDarkMode,
      required this.key,
      required this.name,
      required this.representativeColor,
      required this.primaryColor,
      required this.appBarColor,
      required this.bodyColor,
      required this.cardColor});

  @override
  String toString() {
    return 'ThemeColor{isDarkMode: $isDarkMode, name: $name, primaryColor: $representativeColor, appBarColor: $appBarColor, bodyColor: $bodyColor, cardColor: $cardColor}';
  }
}
