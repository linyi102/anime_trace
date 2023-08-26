import 'package:flutter_test_future/utils/sp_util.dart';

class SeriesStyle {
  static String get keySuffix => 'InSeriesPage';
  static String get useGridKey => 'useGrid$keySuffix';
  static String get showRecommendKey => 'showRecommend$keySuffix';
  static String get sortCondNameKey => 'sortCondName$keySuffix';
  static String get sortDescKey => 'sortDesc$keySuffix';

  static SeriesListSortRule sortRule = SeriesStyle.getSortRule();

  static bool get useGrid => SPUtil.getBool(
        useGridKey,
        defaultValue: true,
      );

  static bool get useList => !useGrid;

  static void enableGrid() {
    SPUtil.setBool(useGridKey, true);
  }

  static void enableList() {
    SPUtil.setBool(useGridKey, false);
  }

  static SeriesListSortRule getSortRule() {
    bool sortDesc = SPUtil.getBool(sortDescKey, defaultValue: false);
    String sortCondName = SPUtil.getString(sortCondNameKey);
    for (var cond in SeriesListSortCond.values) {
      if (cond.name == sortCondName) {
        return SeriesListSortRule(cond: cond, desc: sortDesc);
      }
    }
    return SeriesListSortRule(
        cond: SeriesListSortCond.createTime, desc: sortDesc);
  }

  static void setSortCond(SeriesListSortCond cond) {
    sortRule.cond = cond;
    SPUtil.setString(sortCondNameKey, sortRule.cond.name);
  }

  static void toggleSortDesc() {
    sortRule.desc = !sortRule.desc;
    SPUtil.setBool(sortDescKey, sortRule.desc);
  }

  static void resetSortDesc() {
    sortRule.desc = false;
    SPUtil.setBool(sortDescKey, sortRule.desc);
  }
}

class SeriesListSortRule {
  bool desc; // 是否倒序
  SeriesListSortCond cond; // 排序条件

  SeriesListSortRule(
      {this.cond = SeriesListSortCond.createTime, this.desc = false});
}

enum SeriesListSortCond {
  createTime('创建时间'),
  animeCnt('动漫数量'),
  ;

  final String title; // 标题
  const SeriesListSortCond(this.title);
}
