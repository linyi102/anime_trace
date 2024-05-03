import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/dao/history_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:get/get.dart';

class AnimeAirDateListController extends GetxController {
  List<AnimeAirDateItem> animeAirDateTimeItems = [];
  final unknownAirDate = DateTime(-1);
  final recentWatchDate = DateTime(-2);
  late final recentWatchedAnimeDateItem =
      AnimeAirDateItem(time: recentWatchDate, animes: []);
  List<DateTime> allAirDate = [];

  @override
  void onInit() {
    super.onInit();
    loadAllAnimes();
  }

  Future<void> loadAllAnimes() async {
    animeAirDateTimeItems.clear();
    allAirDate.clear();

    final allAnimes = await AnimeDao.getAllAnimes();
    // 先获取所有时间
    Map<DateTime, List<Anime>> timeMapAnime = {unknownAirDate: []};
    for (final anime in allAnimes) {
      final premiereTime = anime.premiereDateTime;
      if (premiereTime == null) {
        timeMapAnime[unknownAirDate]?.add(anime);
        continue;
      }
      DateTime yearMonth = DateTime(premiereTime.year, premiereTime.month);
      timeMapAnime.putIfAbsent(yearMonth, () => []);
      timeMapAnime[yearMonth]?.add(anime);
    }

    animeAirDateTimeItems.addAll(timeMapAnime.keys.map(
      (e) => AnimeAirDateItem(time: e, animes: timeMapAnime[e] ?? []),
    ));
    // 倒序展示放映时间条目
    animeAirDateTimeItems.sort((a, b) => -a.time.compareTo(b.time));
    // 放映时间条目里的动漫按放映时间顺序排序
    for (final item in animeAirDateTimeItems) {
      item.animes.sort((a, b) => a.premiereTime.compareTo(b.premiereTime));
    }
    // 开头添加最近观看条目
    animeAirDateTimeItems.insert(0, recentWatchedAnimeDateItem);
    // 生成所有放映时间，便于快速跳转
    allAirDate.addAll(animeAirDateTimeItems.map((e) => e.time));
    // 获取最近观看动漫
    await _loadRecentWatchedAnimes();
    update();
  }

  _loadRecentWatchedAnimes() async {
    recentWatchedAnimeDateItem.animes.clear();
    recentWatchedAnimeDateItem.animes
        .addAll(await HistoryDao.recentWatchedAnimes(day: 10));
  }
}

class AnimeAirDateItem {
  final DateTime time;
  final List<Anime> animes;

  AnimeAirDateItem({
    required this.time,
    required this.animes,
  });
}
