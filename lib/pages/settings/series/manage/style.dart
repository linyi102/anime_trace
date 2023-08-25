import 'package:flutter_test_future/utils/sp_util.dart';

class SeriesStyle {
  String get keySuffix => 'InSeriesPage';
  String get useGridKey => 'useGrid$keySuffix';
  String get showRecommendKey => 'showRecommend$keySuffix';

  bool get useGrid => SPUtil.getBool(
        useGridKey,
        defaultValue: true,
      );

  bool get useList => !useGrid;

  void enableGrid() {
    SPUtil.setBool(useGridKey, true);
  }

  void enableList() {
    SPUtil.setBool(useGridKey, false);
  }

  bool get showRecommend =>
      SPUtil.getBool(showRecommendKey, defaultValue: true);

  void turnOnRecommend() {
    SPUtil.setBool(showRecommendKey, true);
  }

  void turnOffRecommend() {
    SPUtil.setBool(showRecommendKey, false);
  }
}
