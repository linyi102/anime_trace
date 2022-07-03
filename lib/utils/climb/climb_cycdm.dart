import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/filter.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/climb_omofun.dart';

// 次元城动漫
class ClimbCycdm implements Climb {
  @override
  String baseUrl = "https://www.cycacg.com";

  @override
  Future<Anime> climbAnimeInfo(Anime anime) async {
    anime = await ClimbOmofun().climbAnimeInfo(anime);
    return anime;
  }

  @override
  Future<List<Anime>> climbAnimesByKeyword(String keyword) async {
    String url = baseUrl + "/vodsearch/-------------.html?wd=$keyword";
    List<Anime> climbAnimes = await ClimbOmofun()
        .climbAnimesByKeyword(keyword, url: url, foreignBaseUrl: baseUrl);
    return climbAnimes;
  }

  @override
  Future<List<Anime>> climbDirectory(Filter filter) async {
    return [];
  }
}
