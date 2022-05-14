import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/sp_util.dart';

class ThemeUtil {
  // 目录页中的过滤组件使用了该颜色
  static Color getScaffoldBackgroundColor() {
    return SPUtil.getBool("enableDark")
        // ? const Color.fromRGBO(25, 25, 25, 1)
        ? const Color.fromRGBO(48, 48, 48, 1)
        : const Color.fromRGBO(250, 250, 250, 1);
    // : const Color.fromRGBO(235, 236, 240, 1);
    // : const Color.fromRGBO(245, 245, 245, 1);
  }

  // 按钮颜色
  static Color getIconButton() {
    return SPUtil.getBool("enableDark") ? Colors.white70 : Colors.black87;
  }

  // 普通字体颜色
  static Color getFontColor() {
    return SPUtil.getBool("enableDark") ? Colors.white70 : Colors.black87;
  }

  // 目录页中，动漫详细信息(别名、首播时间等)的字体颜色
  static Color getCommentColor() {
    return SPUtil.getBool("enableDark")
        // ? const Color.fromRGBO(25, 25, 25, 1)
        ? Colors.white54
        : Colors.black54;
  }

  // 动漫详细页图片背景混合
  static Color getModulateColor() {
    return SPUtil.getBool("enableDark")
        ? const Color.fromRGBO(150, 150, 150, 0.9)
        : const Color.fromRGBO(255, 255, 255, 0.9);
  }

  // 动漫详细页图片背景渐变
  static List<Color> getGradientColors() {
    int baseColorInt;
    if (SPUtil.getBool("enableDark")) {
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
    return SPUtil.getBool("enableDark")
        ? const Color.fromRGBO(48, 48, 48, 1)
        : const Color.fromRGBO(250, 250, 250, 1);
  }

  // 动漫详细页集ListTile颜色
  static Color getEpisodeListTile(bool isChecked) {
    if (isChecked) {
      return SPUtil.getBool("enableDark") ? Colors.white54 : Colors.black54;
    }
    return SPUtil.getBool("enableDark") ? Colors.white70 : Colors.black87;
  }

  // 笔记列表页中笔记的背景色
  static Color getNoteCardColor() {
    return SPUtil.getBool("enableDark")
        ? const Color.fromRGBO(48, 48, 48, 1)
        : Colors.white;
  }

  // 笔记列表页的背景色
  static Color getNoteListBackgroundColor() {
    return SPUtil.getBool("enableDark")
        // ? const Color.fromRGBO(25, 25, 25, 1)
        ? const Color.fromRGBO(66, 66, 66, 1)
        : const Color.fromRGBO(235, 236, 240, 1);
    // : const Color.fromRGBO(245, 245, 245, 1);
  }
}
