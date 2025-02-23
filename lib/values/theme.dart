import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/extensions/color.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class AppTheme {
  /// 圆角
  static double get cardRadius => 8.0;
  static double get imgRadius => 8.0;
  static double get noteImgRadius => 8.0; // 笔记图片
  static double get noteImageSpacing => 6.0; // 笔记图片间隔
  static double get stateRadius => 6.0; // 集数、观看次数
  static double get bottomSheetRadius => 16.0;
  static double get chipRadius => 40.0;
  static double get timePickerDialogRadius => 16.0;
  static double get dialogRadius => 16.0;
  static double get textButtonRadius => 99.0;

  /// 底部面板宽度
  static BoxConstraints get bottomSheetBoxConstraints =>
      const BoxConstraints(maxWidth: 600);

  /// 表单最大宽度
  static double get formMaxWidth => 500;

  /// 半透明背景
  static final translucentBgColor = Colors.black.withOpacityFactor(0.5);

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
  static List<IconData> darkModeIcons = [
    Platform.isWindows
        ? MingCuteIcons.mgc_windows_fill
        : MingCuteIcons.mgc_android_2_fill,
    MingCuteIcons.mgc_sun_2_fill,
    MingCuteIcons.mgc_partly_cloud_night_fill,
  ];
  static List<String> darkModes = ["系统", "白天", "夜间"];

  static Color get blueInLight => const Color(0xFF1976D2);

  // 可选：70, 133, 243 | 61, 129, 228
  static Color get blueInDark => const Color.fromRGBO(70, 133, 243, 1);

  /// 亮色主题
  static List<ThemeColor> lightColors = [
    ThemeColor(
        isDarkMode: false,
        key: "white",
        name: "白色",
        representativeColor: const Color.fromRGBO(248, 248, 248, 1),
        primaryColor: blueInLight,
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
      primaryColor: blueInDark,
      representativeColor: const Color.fromRGBO(50, 50, 50, 1),
      appBarColor: const Color.fromRGBO(24, 24, 24, 1),
      bodyColor: const Color.fromRGBO(18, 18, 18, 1),
      cardColor: const Color.fromRGBO(24, 24, 24, 1),
    ),
    ThemeColor(
        isDarkMode: true,
        key: "pureBlack",
        name: "纯黑",
        primaryColor: blueInDark,
        representativeColor: Colors.black,
        appBarColor: const Color.fromRGBO(14, 14, 14, 1),
        bodyColor: const Color.fromRGBO(8, 8, 8, 1),
        cardColor: const Color.fromRGBO(14, 14, 14, 1)),
    ThemeColor(
      isDarkMode: true,
      key: "nightPurple",
      name: "夜紫",
      primaryColor: const Color.fromRGBO(90, 106, 213, 1.0),
      representativeColor: const Color.fromARGB(255, 62, 73, 131),
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
