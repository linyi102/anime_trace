import 'package:flutter/material.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/dao/series_dao.dart';
import 'package:flutter_test_future/models/series.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:get/get.dart';

class SeriesManageLogic extends GetxController {
  // 所有系列
  List<Series> seriesList = [];
  // 推荐创建的系列
  List<Series> recommendSeriesList = [];

  var inputKeywordController = TextEditingController();
  String kw = "";

  int get recommendSeriesId => -1;
  int animeId;
  bool get enableSelectSeriesForAnime => animeId > 0;

  SeriesManageLogic(this.animeId);

  @override
  void onInit() {
    super.onInit();
    getAllSeries();
  }

  @override
  void dispose() {
    inputKeywordController.dispose();
    super.dispose();
  }

  // 还原数据后，需要重新获取所有系列
  Future<void> getAllSeries() async {
    seriesList = await SeriesDao.getAllSeries();
    // 获取所有系列后，再根据所有系列生成推荐系列
    await getRecommendSeries();
    update();
  }

  Future<void> getRecommendSeries() async {
    recommendSeriesList.clear();

    if (enableSelectSeriesForAnime) {
      // 如果是动漫详情页进入的，则根据当前动漫生成推荐系列(只会生成1个)
      var anime = await SqliteUtil.getAnimeByAnimeId(animeId);
      String recommendSeriesName = _getRecommendSeriesName(anime.animeName);
      if (recommendSeriesName.isEmpty) {
        // 如果不是系列，则推荐根据动漫名字创建系列
        recommendSeriesName = anime.animeName;
      }
      int index = seriesList
          .indexWhere((_series) => _series.name == recommendSeriesName);
      // 先看所有系列中是否有，若有，但没有加入该系列，则显示加入，如还没有创建，则显示创建并加入

      if (index >= 0) {
        if (seriesList[index]
                .animes
                .indexWhere((_anime) => _anime.animeId == animeId) >=
            0) {
          // 该系列创建了，且已加入，那么什么都不做
        } else {
          // 该系列创建了，但没有加入，放到推荐中
          recommendSeriesList.add(seriesList[index]);
        }
      } else {
        // 没有创建该系列，放到推荐中
        recommendSeriesList.add(Series(recommendSeriesId, recommendSeriesName));
      }
    } else {
      // 否则根据收藏的所有动漫生成推荐系列
      var animes = await AnimeDao.getAllAnimes();
      for (var anime in animes) {
        String recommendSeriesName = _getRecommendSeriesName(anime.animeName);
        if (recommendSeriesName.isNotEmpty &&
            _isNotRecommended(recommendSeriesName)) {
          recommendSeriesList
              .add(Series(recommendSeriesId, recommendSeriesName));
        }
      }
    }

    update();
  }

  /// 还没推荐过(推荐系列中和所有系列中都没有)
  bool _isNotRecommended(String seriesName) {
    return recommendSeriesList
                .indexWhere((element) => element.name == seriesName) <
            0 &&
        seriesList.indexWhere((element) => element.name == seriesName) < 0;
  }

  /// 根据动漫名推出系列名
  String _getRecommendSeriesName(String name) {
    RegExp regExp =
        RegExp("(第.*(部|季|期)|ova|Ⅱ|oad|2 |剧场版)", caseSensitive: false);
    var match = regExp.firstMatch(name);
    if (match == null || match[0] == null) return '';
    String seasonText = match[0]!;
    return name.substring(0, name.indexOf(seasonText)).trim();
  }
}
