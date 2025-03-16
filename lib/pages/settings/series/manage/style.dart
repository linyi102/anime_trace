import 'package:animetrace/utils/sp_util.dart';

class SeriesStyle {
  static String get _keySuffix => 'InSeriesPage';
  static String get _useGridKey => 'useGrid$_keySuffix';
  static String get _sortCondNameKey => 'sortCondName$_keySuffix';
  static String get _sortDescKey => 'sortDesc$_keySuffix';
  static String get _useSingleCoverKey => 'useSingleCover$_keySuffix';
  static String get _itemCoverHeight => 'itemCoverHeight$_keySuffix';

  static SeriesListSortRule sortRule = SeriesStyle.getSortRule();

  static bool get useGrid => SPUtil.getBool(
        _useGridKey,
        defaultValue: true,
      );

  static bool get useList => !useGrid;

  static bool get useSingleCover =>
      SPUtil.getBool(_useSingleCoverKey, defaultValue: true);

  static void enableGrid() {
    SPUtil.setBool(_useGridKey, true);
  }

  static void enableList() {
    SPUtil.setBool(_useGridKey, false);
  }

  static void toggleUseSingleCover() {
    SPUtil.setBool(_useSingleCoverKey, !useSingleCover);
  }

  static double getItemCoverHeight() {
    return SPUtil.getDouble(_itemCoverHeight, defaultValue: 100);
  }

  static void setItemCoverHeight(double height) {
    SPUtil.setDouble(_itemCoverHeight, height);
  }

  static SeriesListSortRule getSortRule() {
    bool sortDesc = SPUtil.getBool(_sortDescKey, defaultValue: false);
    String sortCondName = SPUtil.getString(_sortCondNameKey);
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
    SPUtil.setString(_sortCondNameKey, sortRule.cond.name);
  }

  static void toggleSortDesc() {
    sortRule.desc = !sortRule.desc;
    SPUtil.setBool(_sortDescKey, sortRule.desc);
  }

  static void resetSortDesc() {
    sortRule.desc = false;
    SPUtil.setBool(_sortDescKey, sortRule.desc);
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
