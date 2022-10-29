import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/climb_omofun.dart';

// 次元城动漫
class ClimbCycdm implements Climb {
  @override
  // String baseUrl = "https://www.cycacg.com";
  String baseUrl = "https://www.cycdm01.top"; // 2022.10.27

  @override
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    anime = await ClimbOmofun().climbAnimeInfo(anime, showMessage: showMessage);
    return anime;
  }

  @override
  Future<List<Anime>> climbAnimesByKeyword(String keyword) async {
    String url = baseUrl + "/search.html?wd=$keyword";
    List<Anime> climbAnimes = await ClimbOmofun()
        .climbAnimesByKeyword(keyword, url: url, foreignBaseUrl: baseUrl);
    return climbAnimes;
  }

  @override
  Future<List<Anime>> climbDirectory(AnimeFilter filter) async {
    return [];
  }
}
