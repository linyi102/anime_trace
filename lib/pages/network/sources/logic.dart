import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/dao/history_dao.dart';
import 'package:get/get.dart';

import '../../../dao/anime_dao.dart';
import '../../../models/anime.dart';

class AggregateLogic extends GetxController {
  static AggregateLogic get to => Get.find();

  // 去年今天开播的动漫
  List<Anime> animesNYearsAgoTodayBroadcast = [];
  bool loadingAnimesNYearsAgoTodayBroadcast = true;

  // 最近观看的动漫
  List<Anime> recentWatchedAnimes = [];
  bool loadingRecentWatchedAnimes = true;

  // 最近更新的动漫
  List<Anime> get recentUpdateAnimes {
    final animes = UpdateRecordController.to.updateRecordVos.map((record) {
      record.anime.tempInfo = '更新至 ${record.newEpisodeCnt} 集';
      return record.anime;
    }).toList();
    // return animes.sublist(0, animes.length.clamp(0, 20));
    return animes;
  }

  bool get loadingRecentUpdateAnimes => !UpdateRecordController.to.loadOk.value;

  @override
  void onInit() {
    super.onInit();
    loadAnimes();
  }

  Future<void> loadAnimes() async {
    await Future.wait([
      _loadAnimesNYearsAgoTodayBroadcast(),
      _loadRecentWatchedAnimes(),
    ]);
  }

  Future<void> _loadAnimesNYearsAgoTodayBroadcast() async {
    loadingAnimesNYearsAgoTodayBroadcast = true;
    update();

    animesNYearsAgoTodayBroadcast = await AnimeDao.getAnimesNYearAgoToday();
    // 时间早的在最后
    animesNYearsAgoTodayBroadcast.sort(
      (a, b) => -a.premiereTime.compareTo(b.premiereTime),
    );

    loadingAnimesNYearsAgoTodayBroadcast = false;
    update();
  }

  Future<void> _loadRecentWatchedAnimes() async {
    loadingRecentWatchedAnimes = true;
    update();
    recentWatchedAnimes = await HistoryDao.recentWatchedAnimes(day: 10);
    loadingRecentWatchedAnimes = false;
    update();
  }
}
