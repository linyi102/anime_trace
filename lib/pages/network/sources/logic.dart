import 'package:get/get.dart';

import '../../../dao/anime_dao.dart';
import '../../../models/anime.dart';

class AggregateLogic extends GetxController {
  static AggregateLogic get to => Get.find();

  // 去年今天开播的动漫
  List<Anime> animesNYearsAgoTodayBroadcast = [];
  bool loadingAnimesNYearsAgoTodayBroadcast = true;

  @override
  void onInit() {
    super.onInit();
    loadAnimesNYearsAgoTodayBroadcast();
  }

  loadAnimesNYearsAgoTodayBroadcast() async {
    loadingAnimesNYearsAgoTodayBroadcast = true;
    update();

    animesNYearsAgoTodayBroadcast.clear();
    animesNYearsAgoTodayBroadcast = await AnimeDao.getAnimesNYearAgoToday();
    // 时间早的在最后
    animesNYearsAgoTodayBroadcast.sort(
      (a, b) => -a.premiereTime.compareTo(b.premiereTime),
    );

    loadingAnimesNYearsAgoTodayBroadcast = false;
    update();
  }
}
