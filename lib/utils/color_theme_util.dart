import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/sp_util.dart';

class ColorThemeUtil {
  static Color getScaffoldBackgroundColor() {
    return SPUtil.getBool("enableDark")
        // ? const Color.fromRGBO(25, 25, 25, 1)
        ? const Color.fromRGBO(48, 48, 48, 1)
        : const Color.fromRGBO(250, 250, 250, 1);
  }

  static Color getAppBarTitleColor() {
    return SPUtil.getBool("enableDark")
        ? const Color.fromRGBO(217, 217, 217, 1)
        : Colors.black;
  }

  static Color getListTileColor() {
    return SPUtil.getBool("enableDark")
        // ? const Color.fromRGBO(170, 170, 170, 1)
        ? const Color.fromRGBO(247, 247, 247, 1)
        : Colors.black;
  }

  static Color getIconColor() {
    return SPUtil.getBool("enableDark")
        ? const Color.fromRGBO(196, 196, 196, 1)
        : Colors.black;
  }

  static Color? getBottomNaviBarSelectedItemColor() {
    return SPUtil.getBool("enableDark")
        ? const Color.fromRGBO(255, 255, 255, 1)
        : null;
  }

  static Color? getBottomNaviBarUnselectedItemColor() {
    return SPUtil.getBool("enableDark")
        ? const Color.fromRGBO(193, 193, 193, 1)
        : null;
  }
}
