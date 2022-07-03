import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:get/get.dart';

class ThemeUtil {
  static final ThemeController themeController = Get.find();
  // 主题色
  static Color getThemePrimaryColor() {
    Color color = Colors.blue;
    color = const Color.fromRGBO(0, 206, 209, 1); // 深绿宝石
    color = const Color.fromRGBO(82, 82, 136, 1); // 野菊紫
    color = const Color.fromRGBO(239, 71, 93, 1); // 草茉莉红
    color = const Color.fromRGBO(255, 127, 80, 1); // 珊瑚
    color = const Color.fromRGBO(32, 178, 170, 1); // 浅海洋绿
    color = const Color.fromRGBO(192, 72, 81, 1); // 玉红
    color = Colors.amber;
    color = Colors.lightBlue;
    color = Colors.blue;
    color = const Color.fromRGBO(86, 152, 195, 1); // 睛蓝
    color = const Color.fromRGBO(0, 191, 255, 1); // 深天蓝
    color = const Color.fromRGBO(7, 176, 242, 1);
    return color;
  }

  // ListTile>leading按钮颜色
  static Color getLeadingIconColor() {
    return ThemeUtil.getThemePrimaryColor();
  }

  // 顶部栏背景色
  // 目录页中的过滤组件也使用了该颜色
  static Color getAppBarBackgroundColor() {
    return themeController.isDarkMode.value
        ? const Color.fromRGBO(48, 48, 48, 1)
        : Colors.white;
  }

  // 主体背景色
  static Color getScaffoldBackgroundColor() {
    return themeController.isDarkMode.value
        ? const Color.fromRGBO(43, 43, 43, 1)
        : const Color.fromRGBO(250, 250, 250, 1);
    // : const Color.fromRGBO(250, 251, 254, 1);
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
      baseColorInt = 43; // 对应动漫详细页面下面的背景色
    } else {
      baseColorInt = 250;
    }
    return [
      // Colors.transparent,
      Color.fromRGBO(baseColorInt, baseColorInt, baseColorInt, 0),
      Color.fromRGBO(baseColorInt, baseColorInt, baseColorInt, 0.1),
      Color.fromRGBO(baseColorInt, baseColorInt, baseColorInt, 0.2),
      Color.fromRGBO(baseColorInt, baseColorInt, baseColorInt, 0.5),
      // Color.fromRGBO(baseColorInt, baseColorInt, baseColorInt, 0.8),
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
        ? const Color.fromRGBO(43, 43, 43, 1)
        // ? const Color.fromRGBO(66, 66, 66, 1)
        // : const Color.fromRGBO(235, 236, 240, 1);
        : const Color.fromRGBO(245, 245, 245, 1);
  }
}
