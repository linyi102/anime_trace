import 'package:animetrace/dao/key_value_dao.dart';
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
}
