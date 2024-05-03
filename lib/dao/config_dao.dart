import 'package:flutter_test_future/dao/key_value_dao.dart';

class ConfigDao {
  /// 获取忽略的推荐系列
  static Future<List<String>> getIgnoredRecommendSeries() async {
    return await KeyValueDao.getStringList('ignoredRecommendSeries') ?? [];
  }

  /// 设置忽略的推荐系列
  static Future<void> setIgnoredRecommendSeries(List<String> names) async {
    await KeyValueDao.setStringList('ignoredRecommendSeries', names);
  }
}
