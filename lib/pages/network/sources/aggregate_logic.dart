import 'package:animetrace/controllers/update_record_controller.dart';
import 'package:animetrace/dao/history_dao.dart';
import 'package:animetrace/models/climb_website.dart';
import 'package:animetrace/utils/dio_util.dart';
import 'package:animetrace/utils/global_data.dart';
import 'package:animetrace/utils/log.dart';
import 'package:get/get.dart';

import '../../../dao/anime_dao.dart';
import '../../../models/anime.dart';

class AggregateLogic extends GetxController {
  static AggregateLogic get to => Get.find();
  List<ClimbWebsite> usableWebsites = [];
  bool pingFinished = true;

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
    // 网格只显示可用的搜索源
    usableWebsites = climbWebsites.where((e) => !e.discard).toList();
    loadData();
  }

  Future<void> loadData() async {
    await Future.wait([
      pingAllWebsites(),
      _loadAnimesNYearsAgoTodayBroadcast(),
      _loadRecentWatchedAnimes(),
    ]);
  }

  Future<void> pingAllWebsites() async {
    if (!pingFinished) return;

    pingFinished = false;
    update();

    for (var website in climbWebsites) {
      website.pingStatus.needPing = true;
    }
    for (var website in climbWebsites) {
      if (!website.discard && website.pingStatus.needPing) {
        website.pingStatus.connectable = false; // 表示不能连接(ping时显示灰色)
        website.pingStatus.pinging = true; // 表示正在ping
      }
    }
    update();

    List<Future> futures = [];
    for (var website in climbWebsites) {
      if (!website.discard && website.pingStatus.needPing) {
        futures.add(DioUtil.ping(website.climb.baseUrl).then((value) {
          website.pingStatus = value;
          update();
          Log.info("${website.name}:pingStatus=${website.pingStatus}");
        }));
      }
    }
    await Future.wait(futures);
    pingFinished = true;
    update();
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
