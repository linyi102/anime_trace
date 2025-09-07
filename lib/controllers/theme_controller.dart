import 'package:flutter/material.dart';
import 'package:animetrace/utils/settings.dart';
import 'package:animetrace/utils/sp_profile.dart';
import 'package:animetrace/utils/sp_util.dart';
import 'package:animetrace/values/values.dart';
import 'package:get/get.dart';

const _primaryColorKey = 'customPrimaryColor';

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  /// 主题模式
  final themeModeIdx = SPUtil.getInt("darkMode", defaultValue: 0).obs;

  bool isDark(context) => Theme.of(context).brightness == Brightness.dark;

  /// 主题色
  late final primaryColor = getPrimaryColor().obs;

  /// 配色方案
  late final dynamicSchemeVariant = getDynamicSchemeVariant().obs;

  /// 隐藏移动端底部标签栏
  final hideMobileBottomLabel =
      SettingsUtil.get<bool>(SettingsEnum.hideMobileBottomLabel).obs;

  /// 页面切换动画
  final pageSwitchAnimation = SpProfile.getPageSwitchAnimation().obs;

  /// 字体
  final fontFamilyFallback = [
    '苹方-简',
    'PingFang SC',
    'HarmonyOS Sans SC',
    'Noto Sans SC',
    'Microsoft YaHei UI',
    '微软雅黑',
  ].obs;

  Future<bool> changePrimaryColor(Color color) async {
    primaryColor.value = color;
    return SPUtil.setInt(_primaryColorKey, color.value);
  }

  Future<bool> resetPrimaryColor() async {
    primaryColor.value = Colors.blueAccent;
    return SPUtil.remove(_primaryColorKey);
  }

  Color getPrimaryColor() {
    final colorValue = SPUtil.getInt(_primaryColorKey);
    if (colorValue == 0) return Colors.blueAccent;
    return Color(colorValue);
  }

  void setDynamicSchemeVariant(DynamicSchemeVariant variant) {
    dynamicSchemeVariant.value = variant;
    SPUtil.setString('dynamicSchemeVariant', variant.name);
  }

  DynamicSchemeVariant getDynamicSchemeVariant() {
    final variant = SPUtil.getString('dynamicSchemeVariant');
    return DynamicSchemeVariant.values.firstWhere((e) => e.name == variant,
        orElse: () => DynamicSchemeVariant.fruitSalad);
  }

  void setThemeMode(int themeModeIdx) {
    this.themeModeIdx.value = themeModeIdx;
    SPUtil.setInt("darkMode", themeModeIdx);
  }

  ThemeMode getThemeMode() {
    return AppTheme.themeModes[themeModeIdx.value];
  }
}

extension DynamicSchemeVariantX on DynamicSchemeVariant {
  String get displayName => switch (this) {
        DynamicSchemeVariant.tonalSpot => '色调点',
        DynamicSchemeVariant.fidelity => '保真',
        DynamicSchemeVariant.monochrome => '单色',
        DynamicSchemeVariant.neutral => '中性',
        DynamicSchemeVariant.vibrant => '鲜艳',
        DynamicSchemeVariant.expressive => '表现力',
        DynamicSchemeVariant.content => '内容',
        DynamicSchemeVariant.rainbow => '彩虹',
        DynamicSchemeVariant.fruitSalad => '水果沙拉',
      };
}
