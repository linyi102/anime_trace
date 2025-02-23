import 'package:animetrace/models/anime.dart';
import 'package:animetrace/utils/climb/climb.dart';
import 'package:animetrace/utils/climb/same_ui/climb_cyc_ui.dart';

class ClimbNyaFun with Climb {
  @override
  String get idName => "nayFun";

  @override
  String get defaultBaseUrl => "https://www.nyacg.net";

  @override
  String get sourceName => "NyaFun";

  @override
  Future<Anime> climbAnimeInfo(Anime anime) async {
    final document = await dioGetAndParse(anime.animeUrl);
    if (document == null) return anime;
    return CycUIClimber.detail(document, anime);
  }

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    String url = baseUrl + "/search.html?wd=$keyword";
    final document = await dioGetAndParse(url);
    if (document == null) return [];
    return CycUIClimber.search(document, baseUrl);
  }
}
