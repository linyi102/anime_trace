import 'package:flutter/material.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/dao/series_dao.dart';
import 'package:flutter_test_future/models/series.dart';
import 'package:flutter_test_future/pages/settings/series/manage/style.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:get/get.dart';

class SeriesManageLogic extends GetxController {
  String tag;
  SeriesManageLogic({required this.tag, required this.animeId});

  // 所有系列
  List<Series> allSeriesList = [];
  bool loadingSeriesList = true;

  // 推荐创建的系列
  List<Series> allRecommendSeriesList = []; // 所有推荐
  List<Series> animeRecommendSeriesList = []; // 当前动漫推荐
  bool loadingRecommendSeriesList = true;

  // 搜索
  var inputKeywordController = TextEditingController();
  String kw = "";

  // 推荐系列，因为可能还没有创建，此时指定id为-1
  int get recommendSeriesId => -1;

  int animeId; // 动漫详情页传来的动漫id
  bool get enableSelectSeriesForAnime => animeId > 0; // 表明动漫详情页进入的系列页

  @override
  void onInit() {
    super.onInit();
    // 避免路由动画时查询数据库导致动画卡顿
    Future.delayed(const Duration(milliseconds: 100))
        .then((value) => getAllSeries());
  }

  @override
  void dispose() {
    inputKeywordController.dispose();
    super.dispose();
  }

  // 还原数据后，需要重新获取所有系列
  Future<void> getAllSeries() async {
    allSeriesList = await SeriesDao.getAllSeries();
    // 排序
    _sort(allSeriesList, SeriesStyle.sortRule);
    loadingSeriesList = false;
    // 动漫详情页进入系列页后，推荐还没生成，此时显示全部，推荐生成后会导致突然下移(闪烁)，所以此处不进行重绘
    // 而是等推荐系列生成完毕后一起显示
    // update();

    // 获取所有系列后，再根据所有系列生成推荐系列
    await getAnimeRecommendSeries();
    await getRecommendSeries();
    loadingRecommendSeriesList = false;
    update();
  }

  Future<void> getAnimeRecommendSeries() async {
    if (!enableSelectSeriesForAnime) return;

    List<Series> list = [];

    if (enableSelectSeriesForAnime) {
      // 如果是动漫详情页进入的，则根据当前动漫生成推荐系列(只会生成1个)
      var anime = await SqliteUtil.getAnimeByAnimeId(animeId);
      String recommendSeriesName = _getRecommendSeriesName(anime.animeName);
      if (recommendSeriesName.isEmpty) {
        // 如果不是系列，则推荐根据动漫名字创建系列
        recommendSeriesName = anime.animeName;
      }
      int index = allSeriesList
          .indexWhere((_series) => _series.name == recommendSeriesName);
      // 先看所有系列中是否有，若有，但没有加入该系列，则显示加入，如还没有创建，则显示创建并加入

      if (index >= 0) {
        if (allSeriesList[index]
                .animes
                .indexWhere((_anime) => _anime.animeId == animeId) >=
            0) {
          // 该系列创建了，且已加入，那么什么都不做
        } else {
          // 该系列创建了，但没有加入，放到推荐中
          list.add(allSeriesList[index]);
        }
      } else {
        // 没有创建该系列，放到推荐中
        list.add(Series(recommendSeriesId, recommendSeriesName));
      }
    }

    animeRecommendSeriesList = list;
    update();
  }

  Future<void> getRecommendSeries() async {
    // 不要用clear，然后直接添加到recommendSeriesList
    // 因为在获取已创建的全部系列后会进行重绘，如果再重绘前清空了recommendSeriesList，会丢失滚动位置
    // 因此先存放到list，最终统一赋值给recommendSeriesList
    List<Series> list = [];

    // 否则根据收藏的所有动漫生成推荐系列
    var animes = await AnimeDao.getAllAnimes();
    for (var anime in animes) {
      String recommendSeriesName = _getRecommendSeriesName(anime.animeName);
      if (recommendSeriesName.isNotEmpty &&
          _isNotRecommended(recommendSeriesName, list) &&
          // 为该动漫推荐了，则不在全部里展示
          animeRecommendSeriesList.indexWhere(
                  (element) => element.name == recommendSeriesName) <
              0) {
        list.add(Series(recommendSeriesId, recommendSeriesName));
      }
    }

    allRecommendSeriesList = list;
    update();
  }

  /// 还没推荐过(推荐系列中和所有系列中都没有)
  bool _isNotRecommended(
      String seriesName, List<Series> currentRecommentSeriesList) {
    return currentRecommentSeriesList
                .indexWhere((element) => element.name == seriesName) <
            0 &&
        allSeriesList.indexWhere((element) => element.name == seriesName) < 0;
  }

  /// 根据动漫名推出系列名
  String _getRecommendSeriesName(String name) {
    RegExp regExp = RegExp("(第.*(部|季|期)|ova|oad|剧场版|[1-9] |Ⅰ|Ⅱ|Ⅲ|Ⅳ|Ⅴ)",
        caseSensitive: false);
    var match = regExp.firstMatch(name);
    if (match == null || match[0] == null) return '';
    String seasonText = match[0]!;
    return name.substring(0, name.indexOf(seasonText)).trim();
  }

  sort() {
    _sort(allSeriesList, SeriesStyle.sortRule);
    update();
  }

  void _sort(List<Series> seriesList, SeriesListSortRule rule) {
    switch (rule.cond) {
      case SeriesListSortCond.createTime:
        seriesList.sort(
          (a, b) => rule.desc ? -a.id.compareTo(b.id) : a.id.compareTo(b.id),
        );
        break;
      case SeriesListSortCond.animeCnt:
        seriesList.sort(
          (a, b) {
            var alen = a.animes.length, blen = b.animes.length;
            // 动漫数量一致时，按照id排序，避免删除时，仍然按数量排序时，相同数量的系列的顺序变化
            if (alen == blen) {
              return a.id.compareTo(b.id);
            }

            return rule.desc ? -alen.compareTo(blen) : alen.compareTo(blen);
          },
        );
        break;
      default:
    }
  }
}
