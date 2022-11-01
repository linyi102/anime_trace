import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  var isDarkMode = SPUtil.getBool("enableDark").obs;
  RxList<String> fontFamilyFallback = [
    SPUtil.getString("customFontFamily"),
    '苹方-简',
    'PingFang SC',
    'Microsoft YaHei UI',
    '微软雅黑'
  ].obs;

  changeTheme() {
    // 无法实时显示变化
    // isDarkMode = (!(isDarkMode.value)).obs; // 获取bool类型，取反后再转为RxBool
    isDarkMode.toggle();
    SPUtil.setBool("enableDark", isDarkMode.value);
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
