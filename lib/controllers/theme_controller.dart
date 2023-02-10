import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/page_switch_animation.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:get/get.dart';

import '../utils/theme_util.dart';

class ThemeController extends GetxController {
  // 夜间模式由ThemeColor里的isDarkMode决定
  Rx<ThemeColor> themeColor = acquireSelectedTheme();
  Rx<PageSwitchAnimation> pageSwitchAnimation =
      SpProfile.getPageSwitchAnimation().obs;

  static ThemeController get to => Get.find();

  // 字体
  RxList<String> fontFamilyFallback = [
    SPUtil.getString("customFontFamily"),
    '苹方-简',
    'PingFang SC',
    'Microsoft YaHei UI',
    '微软雅黑'
  ].obs;

  // 从sp中获取用户选择的主题，如果没有，则是white，然后根据这个key从color map中获取相应的ThemeColor
  static acquireSelectedTheme() {
    String key = SPUtil.getString("themeColor", defaultValue: "white");
    return ThemeUtil.getThemeColorByKey(key).obs;
  }

  changeTheme(String key) {
    themeColor.value = ThemeUtil.getThemeColorByKey(key);
    SPUtil.setString("themeColor", key);
  }

  // 字体
  changeFontFamily(String fontFamily) {
    fontFamilyFallback[0] = fontFamily;
    SPUtil.setString("customFontFamily", fontFamily);
  }

  restoreFontFamily() {
    fontFamilyFallback[0] = '';
    SPUtil.setString("customFontFamily", '');
  }
}
