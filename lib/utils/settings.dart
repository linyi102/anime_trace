import 'package:flutter_test_future/utils/sp_util.dart';

enum SettingsEnum<T> {
  hideMobileBottomLabel('hideMobileBottomNavigationBarLabel', false);

  final String key;
  final T defaultValue;
  const SettingsEnum(this.key, this.defaultValue);
}

class SettingsUtil {
  static T getValue<T>(SettingsEnum<T> setting) {
    if (T == bool) {
      return SPUtil.getBool(setting.key,
          defaultValue: setting.defaultValue as bool) as T;
    } else if (T == int) {
      return SPUtil.getInt(setting.key,
          defaultValue: setting.defaultValue as int) as T;
    } else if (T == double) {
      return SPUtil.getDouble(setting.key,
          defaultValue: setting.defaultValue as double) as T;
    } else if (T == String) {
      return SPUtil.getString(setting.key,
          defaultValue: setting.defaultValue as String) as T;
    } else {
      throw Exception('暂不支持该类型：${T.runtimeType}');
    }
  }

  static Future<bool> setValue<T>(SettingsEnum setting, T value) {
    if (T == bool) {
      return SPUtil.setBool(setting.key, value as bool);
    } else if (T == int) {
      return SPUtil.setInt(setting.key, value as int);
    } else if (T == double) {
      return SPUtil.setDouble(setting.key, value as double);
    } else if (T == String) {
      return SPUtil.setString(setting.key, value as String);
    } else {
      throw Exception('暂不支持该类型：${T.runtimeType}');
    }
  }
}
