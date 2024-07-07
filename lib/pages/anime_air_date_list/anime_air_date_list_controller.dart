import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:get/get.dart';

class AnimeAirDateListController extends GetxController {
  List<AnimeAirDateItem> animeAirDateTimeItems = [];
  final unknownAirDate = DateTime(-1);
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
    // 生成所有放映时间，便于快速跳转
    allAirDate.addAll(animeAirDateTimeItems.map((e) => e.time));
    update();
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
