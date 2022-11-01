import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:get/get.dart';

import '../utils/theme_util.dart';

class ThemeController extends GetxController {
  // 从sp中获取用户选择的主题，如果没有，则是white，然后根据这个key从color map中获取相应的ThemeColor
  // 夜间模式由ThemeColor里的isDarkMode决定
  Rx<ThemeColor> themeColor = ThemeUtil
      .themeColors[SPUtil.getString("themeColor", defaultValue: "white")]!.obs;

  // 字体
  RxList<String> fontFamilyFallback = [
    SPUtil.getString("customFontFamily"),
    '苹方-简',
    'PingFang SC',
    'Microsoft YaHei UI',
    '微软雅黑'
  ].obs;

  changeTheme(String id) {
    themeColor.value = ThemeUtil.themeColors[id]!;
    SPUtil.setString("themeColor", id);
  }

  changeFontFamily(String fontFamily) {
    fontFamilyFallback[0] = fontFamily;
    SPUtil.setString("customFontFamily", fontFamily);
  }

  restoreFontFamily() {
    fontFamilyFallback[0] = '';
    SPUtil.setString("customFontFamily", '');
  }
}
