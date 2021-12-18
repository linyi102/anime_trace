import 'package:shared_preferences/shared_preferences.dart';

class SPUtil {
  // 单例模式
  static SPUtil? _instance;

  SPUtil._();

  static Future<SPUtil> getInstance() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    return _instance ??= SPUtil._();
  }

  static late SharedPreferences _sharedPreferences;

  static Future<bool> setString(String key, String value) {
    return _sharedPreferences.setString(key, value);
  }

  static String getString(String key, {String defaultValue = "未设置路径"}) {
    return _sharedPreferences.getString(key) ?? defaultValue;
  }
}
