import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/climb_omofun.dart';

import '../../models/params/page_params.dart';

// 艾米动漫
class ClimbAimi with Climb {
  // 单例
  static final ClimbAimi _instance = ClimbAimi._();
  factory ClimbAimi() => _instance;
  ClimbAimi._();

  @override
  String get idName => "aimi";

  @override
  String get defaultBaseUrl => "https://www.aimidm.com";

  @override
  String get sourceName => "艾米动漫";

  @override
  Future<Anime> climbAnimeInfo(Anime anime) async {
    anime = await ClimbOmofun()
        .climbAnimeInfo(anime, foreignSourceName: sourceName);
    return anime;
  }

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    String url = "$baseUrl/index.php/vod/search.html?wd=$keyword";
    List<Anime> climbAnimes = await ClimbOmofun().searchAnimeByKeyword(keyword,
        url: url, foreignBaseUrl: baseUrl, foreignSourceName: sourceName);
    return climbAnimes;
  }

  @override
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) async {
    return [];
  }
}
