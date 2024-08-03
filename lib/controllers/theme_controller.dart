import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/page_switch_animation.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  Rx<int> themeModeIdx = SPUtil.getInt("darkMode", defaultValue: 0).obs;
  Rx<bool> useM3 = SPUtil.getBool("useM3", defaultValue: true).obs;
  Rx<bool> useCardStyle =
      SPUtil.getBool("useCardStyle", defaultValue: true).obs;

  Rx<ThemeColor> lightThemeColor = getSelectedTheme();
  Rx<ThemeColor> darkThemeColor = getSelectedTheme(dark: true);

  static String customPrimaryColorKey = 'customPrimaryColor';
  Rx<Color?> customPrimaryColor = getCustomPrimaryColor().obs;

  Rx<PageSwitchAnimation> pageSwitchAnimation =
      SpProfile.getPageSwitchAnimation().obs;

  bool isDark(context) => Theme.of(context).brightness == Brightness.dark;

  /// 风格
  setM3(bool enable) {
    useM3.value = enable;
    SPUtil.setBool("useM3", enable);
  }

  setUseCardStyle(bool enable) {
    useCardStyle.value = enable;
    SPUtil.setBool("useCardStyle", enable);
  }

  /// 字体
  RxList<String> fontFamilyFallback = [
    SPUtil.getString("customFontFamily"),
    '苹方-简',
    'PingFang SC',
    'HarmonyOS Sans SC',
    'Noto Sans SC',
    'Microsoft YaHei UI',
    '微软雅黑',
  ].obs;

  /// 从sp中获取用户选择的主题，如果没有，则是white，然后根据这个key从color map中获取相应的ThemeColor
  static getSelectedTheme({bool dark = false}) {
    String themeColorKey = SPUtil.getString(
      dark ? "darkThemeColor" : "lighThemeColor",
      defaultValue: dark ? "lightBlack" : "white",
    );
    return getThemeColorByKey(themeColorKey, dark: dark).obs;
  }

  void changeTheme(String themeColorKey, {bool dark = false}) {
    if (dark) {
      darkThemeColor.value = getThemeColorByKey(themeColorKey, dark: dark);
    } else {
      lightThemeColor.value = getThemeColorByKey(themeColorKey, dark: dark);
    }
    SPUtil.setString(
      dark ? "darkThemeColor" : "lighThemeColor",
      themeColorKey,
    );
  }

  /// 更新主题色
  Future<bool> changeCustomPrimaryColor(Color color) async {
    customPrimaryColor.value = color;
    return SPUtil.setInt(customPrimaryColorKey, color.value);
  }

  Future<bool> resetCustomPrimaryColor() async {
    customPrimaryColor.value = null;
    return SPUtil.remove(customPrimaryColorKey);
  }

  static Color? getCustomPrimaryColor() {
    final colorValue = SPUtil.getInt(customPrimaryColorKey);
    if (colorValue == 0) return null;
    return Color(colorValue);
  }

  /// 根据key从list中查找主题
  static ThemeColor getThemeColorByKey(String key, {bool dark = false}) {
    var colors = dark ? AppTheme.darkColors : AppTheme.lightColors;

    return colors.firstWhereOrNull((themeColor) => themeColor.key == key) ??
        getDefaultThemeColor(dark: dark);
  }

  /// 没有找到时，以第1个作为主题
  static ThemeColor getDefaultThemeColor({bool dark = false}) {
    return dark ? AppTheme.darkColors[0] : AppTheme.lightColors[0];
  }

  /// 深色模式
  void setThemeMode(int themeModeIdx) {
    this.themeModeIdx.value = themeModeIdx;
    SPUtil.setInt("darkMode", themeModeIdx);
  }

  ThemeMode getThemeMode() {
    return AppTheme.themeModes[themeModeIdx.value];
  }

  /// 字体
  changeFontFamily(String fontFamily) {
    fontFamilyFallback[0] = fontFamily;
    SPUtil.setString("customFontFamily", fontFamily);
  }

  restoreFontFamily() {
    fontFamilyFallback[0] = '';
    SPUtil.setString("customFontFamily", '');
  }
}
