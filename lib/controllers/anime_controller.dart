import 'package:get/get.dart';

import '../classes/anime.dart';

class AnimeController extends GetxController {
  Rx<Anime> anime = Anime(animeName: "", animeEpisodeCnt: 0).obs;

  // 首次进入动漫详细页，会把动漫put controller并设置动漫，以便tab页通过get获取controller，然后获取anime
  void setAnime(Anime newAnime) {
    anime.value = newAnime;
  }

  //  其他页面(例如详情页修改了动漫封面)更新动漫时，动漫详细页可以收到通知并重新渲染
  updateAnimeUrl(String animeUrl) {
    anime.update((anime) {
      anime?.animeUrl = animeUrl;
    });
  }

  updateAnimeCoverUrl(String coverUrl) {
    anime.update((anime) {
      anime?.animeCoverUrl = coverUrl;
    });
  }

  updateAnimeName(String newName) {
    anime.update((anime) {
      anime?.animeName = newName;
    });
  }

  updateAnimeNameAnother(String newNameAnother) {
    anime.update((anime) {
      anime?.nameAnother = newNameAnother;
    });
  }

  updateAnimeDesc(String newDesc) {
    anime.update((anime) {
      anime?.animeDesc = newDesc;
    });
  }
}
