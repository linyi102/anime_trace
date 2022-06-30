import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:get/get.dart';

class ThemeUtil {
  static final ThemeController themeController = Get.find();

  // 更多页中的ListTile按钮颜色
  static Color getIconColorOnSettingPage() {
    return themeController.isDarkMode.value ? Colors.white70 : Colors.blue;
  }

  // 目录页中的过滤组件也使用了该颜色
  static Color getAppBarBackgroundColor() {
    return themeController.isDarkMode.value
        ? const Color.fromRGBO(48, 48, 48, 1)
        : Colors.white;
  }

  // 按钮颜色
  static Color getIconButtonColor() {
    return themeController.isDarkMode.value ? Colors.white70 : Colors.black87;
  }

  // 普通字体颜色
  static Color getFontColor() {
    return themeController.isDarkMode.value
        // ? Colors.white70
        ? Colors.white
        : Colors.black87;
  }

  // 目录页中，动漫详细信息(别名、首播时间等)的字体颜色
  static Color getCommentColor() {
    return themeController.isDarkMode.value
        // ? const Color.fromRGBO(25, 25, 25, 1)
        ? Colors.white54
        : Colors.black54;
  }

  // 动漫详细页图片背景混合
  static Color getModulateColor() {
    return themeController.isDarkMode.value
        ? const Color.fromRGBO(150, 150, 150, 0.9)
        : const Color.fromRGBO(255, 255, 255, 0.9);
  }

  // 动漫详细页图片背景渐变
  static List<Color> getGradientColors() {
    int baseColorInt;
    if (themeController.isDarkMode.value) {
      baseColorInt = 48;
    } else {
      baseColorInt = 250;
    }
    return [
      // Colors.transparent,
      // Colors.transparent,
      // Colors.transparent,
      // Colors.transparent,
      // Color.fromRGBO(baseColorInt, baseColorInt, baseColorInt, 0),
      Color.fromRGBO(baseColorInt, baseColorInt, baseColorInt, 0.1),
      // Color.fromRGBO(baseColorInt, baseColorInt, baseColorInt, 0.2),
      // Color.fromRGBO(baseColorInt, baseColorInt, baseColorInt, 0.3),
      // Color.fromRGBO(baseColorInt, baseColorInt, baseColorInt, 0.4),
      // Color.fromRGBO(baseColorInt, baseColorInt, baseColorInt, 0.5),
      // Color.fromRGBO(baseColorInt, baseColorInt, baseColorInt, 0.6),
      Color.fromRGBO(baseColorInt, baseColorInt, baseColorInt, 0.2),
      Color.fromRGBO(baseColorInt, baseColorInt, baseColorInt, 0.5),
      Color.fromRGBO(baseColorInt, baseColorInt, baseColorInt, 1.0),
    ];
  }

  // 动漫详细页图片背景渐变下面的遮挡颜色，用于遮挡细线
  static Color getColorBelowGradientAnimeCover() {
    return themeController.isDarkMode.value
        ? const Color.fromRGBO(48, 48, 48, 1)
        : const Color.fromRGBO(250, 250, 250, 1);
  }

  // 动漫详细页集ListTile颜色
  static Color getEpisodeListTile(bool isChecked) {
    if (isChecked) {
      return themeController.isDarkMode.value ? Colors.white38 : Colors.black54;
    }
    return themeController.isDarkMode.value
        ? Colors.white70
        // ? Colors.white
        : Colors.black87;
  }

  // 笔记列表页中笔记的背景色
  static Color getNoteCardColor() {
    return themeController.isDarkMode.value
        ? const Color.fromRGBO(48, 48, 48, 1)
        : Colors.white;
  }

  // 笔记列表页的背景色
  static Color getNoteListBackgroundColor() {
    return themeController.isDarkMode.value
        // ? const Color.fromRGBO(25, 25, 25, 1)
        ? const Color.fromRGBO(66, 66, 66, 1)
        // : const Color.fromRGBO(235, 236, 240, 1);
        : const Color.fromRGBO(245, 245, 245, 1);
  }
}
