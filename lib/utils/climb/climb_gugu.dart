import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/same_ui/climb_cyc_ui.dart';

class ClimbGugu with Climb {
  @override
  String get idName => "gugu";

  @override
  String get defaultBaseUrl => "https://www.gugu3.com";

  @override
  String get sourceName => "咕咕番";

  @override
  Future<Anime> climbAnimeInfo(Anime anime) async {
    final document = await dioGetAndParse(anime.animeUrl);
    if (document == null) return anime;
    return CycUIClimber.detail(document, anime, playStatusElementIndex: 0);
  }

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    String url = baseUrl + "/index.php/vod/search.html?wd=$keyword";
    final document = await dioGetAndParse(url);
    if (document == null) return [];
    return CycUIClimber.search(document, baseUrl);
  }
}
