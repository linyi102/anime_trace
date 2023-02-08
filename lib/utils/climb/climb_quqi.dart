import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/climb_yhdm.dart';

class ClimbQuqi implements Climb {
  @override
  String baseUrl = "https://www.quqim.net";

  @override
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    return ClimbYhdm().climbAnimeInfo(anime, sourceName: "曲奇动漫");
  }

  @override
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) {
    return ClimbYhdm().climbDirectory(filter, pageParams,
        foreignBaseUrl: baseUrl, sourceName: "曲奇动漫");
  }

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) {
    return ClimbYhdm().searchAnimeByKeyword(keyword,
        foreignBaseUrl: baseUrl, sourceName: "曲奇动漫");
  }
}
