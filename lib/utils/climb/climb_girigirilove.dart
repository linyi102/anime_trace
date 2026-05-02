import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/enum/play_status.dart';
import 'package:animetrace/utils/climb/climb.dart';
import 'package:animetrace/utils/regexp.dart';

class ClimbGGLove with Climb {
  @override
  String get idName => "gugu";

  @override
  String get defaultBaseUrl => "http://bgm.girigirilove.com";

  @override
  String get sourceName => "girigiri愛";

  @override
  Future<Anime> climbAnimeInfo(Anime anime) async {
    final document = await dioGetAndParse(anime.animeUrl);
    if (document == null) return anime;

    var newCover = document
        .getElementsByClassName("detail-pic")
        .firstOrNull
        ?.getElementsByTagName('img')
        .firstOrNull
        ?.attributes["data-src"];
    if (newCover?.isNotEmpty == true) {
      anime.animeCoverUrl = "$baseUrl$newCover";
    }

    String parseMoreItemValue(String? html) {
      if (html == null) return '';
      return html.replaceFirst(RegExp(r'<em.*<\/em>'), '');
    }

    final more = document
        .getElementsByClassName(
            'gen-search-form search-show drawer-scroll-list cor5')
        .firstOrNull
        ?.getElementsByTagName('li');
    anime.premiereTime = RegexpUtil.extractDate(
            parseMoreItemValue(more?.elementAtOrNull(8)?.innerHtml)) ??
        anime.premiereTime;
    anime.playStatus = PlayStatus.text2PlayStatus(parseMoreItemValue(document
            .getElementsByClassName('drawer-scroll-list')
            .firstOrNull
            ?.getElementsByTagName('li')
            .elementAtOrNull(1)
            ?.innerHtml))
        .text;
    anime.animeDesc = parseMoreItemValue(more?.lastOrNull?.innerHtml);
    anime.animeEpisodeCnt = document
            .getElementsByClassName("anthology-list-box")
            .firstOrNull
            ?.getElementsByTagName("li")
            .length ??
        anime.animeEpisodeCnt;
    return anime;
  }

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    String url = baseUrl + "/search/-------------/?wd=$keyword";
    final document = await dioGetAndParse(url);
    if (document == null) return [];

    List<Anime> animes = [];
    final coverEs = document.getElementsByClassName("gen-movie-img");
    for (final coverE in coverEs) {
      String? coverUrl = coverE.attributes["data-src"];
      if (coverUrl == null) continue;
      coverUrl = "$baseUrl$coverUrl";
      animes.add(
          Anime(animeName: "", animeEpisodeCnt: 0, animeCoverUrl: coverUrl));
    }

    final detailEs = document.getElementsByClassName("detail-info");
    for (int i = 0; i < detailEs.length; ++i) {
      final name = detailEs[i]
              .getElementsByClassName("slide-info-title")
              .firstOrNull
              ?.innerHtml ??
          '';
      if (name.isEmpty) continue;

      animes[i].animeName = name;
      String? animeUrl =
          detailEs[i].getElementsByTagName("a").firstOrNull?.attributes["href"];
      animes[i].animeUrl = animeUrl == null ? "" : baseUrl + animeUrl;
    }
    return animes;
  }
}
