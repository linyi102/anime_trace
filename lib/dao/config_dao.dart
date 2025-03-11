import 'package:animetrace/dao/key_value_dao.dart';

class ConfigDao {
  /// 获取忽略的推荐系列
  static Future<List<String>> getIgnoredRecommendSeries() async {
    return await KeyValueDao.getStringList('ignoredRecommendSeries') ?? [];
  }

  /// 设置忽略的推荐系列
  static Future<void> setIgnoredRecommendSeries(List<String> names) async {
    await KeyValueDao.setStringList('ignoredRecommendSeries', names);
  }

  /// 获取搜索历史
  static Future<List<String>> getSearchHistoryKeywords() async {
    return await KeyValueDao.getStringList('networkSearchHistoryKeyword') ?? [];
  }

  /// 设置搜索历史
  static Future<void> setSearchHistoryKeywords(List<String> keywords) async {
    await KeyValueDao.setStringList('networkSearchHistoryKeyword', keywords);
  }
}
