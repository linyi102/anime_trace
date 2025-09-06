import 'dart:io';

import 'package:flutter/material.dart';
import 'package:animetrace/utils/extensions/color.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class AppTheme {
  /// 圆角
  static double get cardRadius => 8.0;
  static double get imgRadius => 12.0; // 封面网格圆角
  static double get coverListRadius => 8.0; // 封面列表圆角
  static double get noteImgRadius => 12.0; // 笔记图片
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
}
