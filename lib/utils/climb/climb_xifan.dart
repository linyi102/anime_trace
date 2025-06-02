import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/enum/play_status.dart';
import 'package:animetrace/utils/climb/climb.dart';
import 'package:animetrace/utils/regexp.dart';

class ClimbXifan with Climb {
  @override
  String get idName => "Xifan";

  @override
  String get defaultBaseUrl => "https://dm.xifanacg.com";

  @override
  String get sourceName => "Xifan";

  @override
  Future<Anime> climbAnimeInfo(Anime anime) async {
    final document = await dioGetAndParse(anime.animeUrl);
    if (document == null) return anime;

    anime.animeCoverUrl = document
            .getElementsByClassName("detail-pic")
            .firstOrNull
            ?.getElementsByTagName('img')
            .firstOrNull
            ?.attributes["data-src"] ??
        anime.animeCoverUrl;

    String parseMoreItemValue(String? html) {
      if (html == null) return '';
      return html.replaceFirst(RegExp(r'<em.*<\/em>'), '');
    }

    final more = document
        .getElementsByClassName(
            'gen-search-form search-show drawer-scroll-list cor5')
        .firstOrNull
        ?.getElementsByTagName('li');
    anime.area = parseMoreItemValue(more?.elementAtOrNull(5)?.innerHtml);
    anime.premiereTime = RegexpUtil.extractDate(
            parseMoreItemValue(more?.elementAtOrNull(8)?.innerHtml)) ??
        anime.premiereTime;
    anime.playStatus = PlayStatus.text2PlayStatus(parseMoreItemValue(more
            ?.elementAtOrNull(1)
            ?.getElementsByTagName('span')
            .elementAtOrNull(0)
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
    String url = baseUrl + "/search.html?wd=$keyword";
    final document = await dioGetAndParse(url);
    if (document == null) return [];

    List<Anime> animes = [];
    final coverEs = document.getElementsByClassName("lazy");
    for (final coverE in coverEs) {
      String? coverUrl = coverE.attributes["data-src"];
      if (coverUrl == null) continue;
      if (coverUrl.startsWith("//")) coverUrl = "https:$coverUrl";
      animes.add(
          Anime(animeName: "", animeEpisodeCnt: 0, animeCoverUrl: coverUrl));
    }

    final nameEs = document.getElementsByClassName("slide-info-title");
    for (int i = 0; i < nameEs.length; ++i) {
      final name = nameEs[i].getElementsByTagName('a').firstOrNull?.innerHtml ??
          nameEs[i].innerHtml;
      if (name.isEmpty) continue;

      animes[i].animeName = name;
      String? animeUrl = nameEs[i].parent?.attributes["href"];
      animes[i].animeUrl = animeUrl == null ? "" : baseUrl + animeUrl;
    }
    return animes;
  }
}
