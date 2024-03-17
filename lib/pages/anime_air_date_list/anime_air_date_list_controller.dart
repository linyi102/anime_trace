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
    animeAirDateTimeItems.sort((a, b) => -a.time.compareTo(b.time));
    animeAirDateTimeItems.insert(0, recentWatchedAnimeDateItem);
    allAirDate.addAll(animeAirDateTimeItems.map((e) => e.time));

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
