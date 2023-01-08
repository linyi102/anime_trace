import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test_future/utils/log.dart';

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

  static String getString(String key, {String defaultValue = ""}) {
    return _sharedPreferences.getString(key) ?? defaultValue;
  }

  static Future<bool> setInt(String key, int value) {
    return _sharedPreferences.setInt(key, value);
  }

  static int getInt(String key, {int defaultValue = 0}) {
    return _sharedPreferences.getInt(key) ?? defaultValue;
  }

  static Future<bool> setBool(String key, bool value) {
    return _sharedPreferences.setBool(key, value);
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    return _sharedPreferences.getBool(key) ?? defaultValue;
  }

  /// 根据key存储double类型
  static Future<bool> setDouble(String key, double value) {
    return _sharedPreferences.setDouble(key, value);
  }

  /// 根据key获取double类型
  static double? getDouble(String key, {double defaultValue = 0.0}) {
    return _sharedPreferences.getDouble(key) ?? defaultValue;
  }

  /// 根据key存储字符串类型数组
  static Future<bool> setStringList(String key, List<String> value) {
    return _sharedPreferences.setStringList(key, value);
  }

  /// 根据key获取字符串类型数组
  static List<String> getStringList(String key, {List<String> defaultValue = const []}) {
    return _sharedPreferences.getStringList(key) ?? defaultValue;
  }

  /// 根据key存储Map类型
  static Future<bool> setMap(String key, Map value) {
    return _sharedPreferences.setString(key, json.encode(value));
  }

  /// 根据key获取Map类型
  static Map getMap(String key) {
    String jsonStr = _sharedPreferences.getString(key) ?? "";
    return jsonStr.isEmpty ? Map : json.decode(jsonStr);
  }

  static Future<bool> clear() async {
    Log.info("清空sharedPreferences");
    return await _sharedPreferences.clear();
  }

  static Future<bool> remove(String key) async {
    Log.info("删除key：$key");
    return await _sharedPreferences.remove(key);
  }
}
