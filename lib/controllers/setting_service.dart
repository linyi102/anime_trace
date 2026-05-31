import 'package:animetrace/dao/key_value_dao.dart';
import 'package:animetrace/models/bangumi/subject_type.dart';
import 'package:animetrace/models/enum/proxy_type.dart';
import 'package:animetrace/utils/sp_util.dart';
import 'package:get/get.dart';

/// 设置服务
///
/// - [KeyValueDao] 基于 Sqlite 数据库，用于永久存储
/// - [SPUtil] 基于 SharedPreferences，用于临时存储
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

  /// 获取是否根据集评分自动计算动漫评分
  Future<bool?> getAutoCalcAnimeRateByEpisode() async {
    return KeyValueDao.getBool('autoCalcAnimeRateByEpisode');
  }

  /// 设置是否根据集评分自动计算动漫评分
  Future<void> setAutoCalcAnimeRateByEpisode(bool value) {
    return KeyValueDao.setBool('autoCalcAnimeRateByEpisode', value);
  }

  /// 获取隐藏底部标签栏
  bool getHideMobileBottomLabel() {
    return SPUtil.getBool('hideMobileBottomNavigationBarLabel',
        defaultValue: false);
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

  /// 获取 Banugmi 搜索类别
  BgmSubjectType getBgmSearchCategory() {
    final r = SPUtil.getString('selectedBangumiSearchCategoryKey',
        defaultValue: BgmSubjectType.all.value);
    return BgmSubjectType.fromValue(r) ?? BgmSubjectType.all;
  }

  /// 设置 Banugmi 搜索类别
  void setBgmSearchCategory(BgmSubjectType category) {
    SPUtil.setString('selectedBangumiSearchCategoryKey', category.value);
  }

  /// 自定义类别
  Future<List<String>?> getAnimeCategories() async {
    return KeyValueDao.getStringList('anime_categories');
  }

  Future<bool> setAnimeCategories(List<String> categries) async {
    return (await KeyValueDao.setStringList('anime_categories', categries)) > 0;
  }

  /// 转发规则
  Future<String> getHosts() async {
    return await KeyValueDao.getString('hosts') ?? '';
  }

  Future<bool> setHosts(String value) async {
    return (await KeyValueDao.setString('hosts', value)) > 0;
  }

  /// 代理类型
  ProxyType getProxyType() {
    return ProxyType.fromValue(SPUtil.getString('proxy_type')) ??
        ProxyType.direct;
  }

  Future<bool> setProxyType(ProxyType type) {
    return SPUtil.setString('proxy_type', type.value);
  }

  /// 代理地址
  String getProxy() {
    return SPUtil.getString('proxy');
  }

  Future<bool> setProxy(String value) {
    return SPUtil.setString('proxy', value);
  }
}
