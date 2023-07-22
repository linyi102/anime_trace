import 'package:get/get.dart';

import '../../../dao/anime_dao.dart';
import '../../../models/anime.dart';

class AggregateLogic extends GetxController {
  // 去年今天开播的动漫
  List<Anime> animesNYearsAgoTodayBroadcast = [];

  @override
  void onInit() {
    super.onInit();
    loadAnimesNYearsAgoTodayBroadcast();
  }

  loadAnimesNYearsAgoTodayBroadcast() async {
    animesNYearsAgoTodayBroadcast.clear();
    animesNYearsAgoTodayBroadcast = await AnimeDao.getAnimesNYearAgoToday();
    // 时间早的在最后
    animesNYearsAgoTodayBroadcast.sort(
      (a, b) => -a.premiereTime.compareTo(b.premiereTime),
    );

    update();
  }
}
