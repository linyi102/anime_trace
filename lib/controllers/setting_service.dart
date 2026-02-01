import 'package:animetrace/dao/key_value_dao.dart';
import 'package:animetrace/utils/sp_util.dart';
import 'package:get/get.dart';

class SettingService extends GetxService {
  static SettingService get to => Get.find();

  /// 获取忽略的推荐系列
  Future<List<String>> getIgnoredRecommendSeries() async {
    return await KeyValueDao.getStringList('ignoredRecommendSeries') ?? [];
  }

  /// 设置忽略的推荐系列
  Future<void> setIgnoredRecommendSeries(List<String> names) async {
    await KeyValueDao.setStringList('ignoredRecommendSeries', names);
  }

  /// 获取搜索历史
  Future<List<String>> getSearchHistoryKeywords() async {
    return await KeyValueDao.getStringList('networkSearchHistoryKeyword') ?? [];
  }

  /// 设置搜索历史
  Future<void> setSearchHistoryKeywords(List<String> keywords) async {
    await KeyValueDao.setStringList('networkSearchHistoryKeyword', keywords);
  }

  /// 获取隐藏底部标签栏
  bool getHideMobileBottomLabel() {
    return SPUtil.getBool('hideMobileBottomNavigationBarLabel', defaultValue: false);
  }

  /// 设置隐藏底部标签栏
  Future<bool> setHideMobileBottomLabel(bool value) {
    return SPUtil.setBool('hideMobileBottomNavigationBarLabel', value);
  }

  /// 获取标签排序模式
  int getLabelSortMode() {
    return SPUtil.getInt('labelSortMode', defaultValue: 0);
  }

  /// 设置标签排序模式
  Future<bool> setLabelSortMode(int mode) {
    return SPUtil.setInt('labelSortMode', mode);
  }

  /// 获取标签是否反向排序
  bool getLabelSortReverse() {
    return SPUtil.getBool('labelSortReverse', defaultValue: false);
  }

  /// 设置标签是否反向排序
  Future<bool> setLabelSortReverse(bool isReverse) {
    return SPUtil.setBool('labelSortReverse', isReverse);
  }
}
