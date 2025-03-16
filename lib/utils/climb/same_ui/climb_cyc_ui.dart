import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/enum/play_status.dart';
import 'package:animetrace/utils/regexp.dart';
import 'package:html/dom.dart';

class CycUIClimber {
  static Future<Anime> detail(
    Document document,
    Anime anime, {
    int playStatusElementIndex = 1,
  }) async {
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
    anime.playStatus = PlayStatus.text2PlayStatus(parseMoreItemValue(document
            .getElementsByClassName('slide-info hide')
            .elementAtOrNull(playStatusElementIndex)
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

  static Future<List<Anime>> search(Document document, String baseUrl) async {
    List<Anime> animes = [];
    final coverEs = document.getElementsByClassName("lazy");
    for (final coverE in coverEs) {
      String? coverUrl = coverE.attributes["data-src"];
      if (coverUrl == null) continue;
      if (coverUrl.startsWith("//")) coverUrl = "https:$coverUrl";
      animes.add(
          Anime(animeName: "", animeEpisodeCnt: 0, animeCoverUrl: coverUrl));
    }

    final nameEs = document.getElementsByClassName("thumb-txt cor4 hide");
    final urlEs = document.getElementsByClassName("public-list-exp");
    for (int i = 0; i < nameEs.length; ++i) {
      final name = nameEs[i].getElementsByTagName('a').firstOrNull?.innerHtml ??
          nameEs[i].innerHtml;
      if (name.isEmpty) continue;

      animes[i].animeName = name;
      String? animeUrl = urlEs[i].attributes["href"];
      animes[i].animeUrl = animeUrl == null ? "" : baseUrl + animeUrl;
    }
    return animes;
  }
}
