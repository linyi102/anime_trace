import 'package:animetrace/controllers/update_record_controller.dart';
import 'package:animetrace/dao/anime_dao.dart';
import 'package:get/get.dart';

class AnimeService extends GetxService {
  static AnimeService get to => Get.find();

  Future<void> deleteAnime(int animeId) async {
    final deleted = await AnimeDao.deleteAnimeByAnimeId(animeId);
    if (deleted) {
      UpdateRecordController.to.removeAnime(animeId);
    }
  }
}
