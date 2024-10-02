import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/enum/play_status.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

class ClimbNyaFun with Climb {
  @override
  String get idName => "nayFun";

  @override
  String get defaultBaseUrl => "https://www.nyacg.net";

  @override
  String get sourceName => "NyaFun";

  @override
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    Log.info("爬取动漫详细网址：${anime.animeUrl}");
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
    anime.premiereTime =
        parseMoreItemValue(more?.elementAtOrNull(8)?.innerHtml);
    anime.playStatus = PlayStatus.text2PlayStatus(parseMoreItemValue(document
            .getElementsByClassName('slide-info hide')
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

    // TODO 统一toast位置
    if (showMessage) ToastUtil.showText("更新完毕");
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

    final nameEs = document.getElementsByClassName("thumb-txt cor4 hide");
    final urlEs = document.getElementsByClassName("public-list-exp");
    for (int i = 0; i < nameEs.length; ++i) {
      final name =
          nameEs[i].getElementsByTagName('a').firstOrNull?.innerHtml ?? '';
      if (name.isEmpty) continue;

      animes[i].animeName = name;
      String? animeUrl = urlEs[i].attributes["href"];
      animes[i].animeUrl = animeUrl == null ? "" : baseUrl + animeUrl;
    }
    return animes;
  }
}
