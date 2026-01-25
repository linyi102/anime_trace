import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/enum/play_status.dart';
import 'package:animetrace/utils/climb/climb.dart';
import 'package:animetrace/utils/regexp.dart';

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

    anime.animeCoverUrl = document
            .getElementsByClassName('detail-pic')
            .firstOrNull
            ?.getElementsByTagName('img')
            .firstOrNull
            ?.attributes["data-src"]
            ?.replaceFirst(RegExp(r'.*url='), '') ??
        anime.animeCoverUrl;

    String parseMoreItemValue(String? html) {
      if (html == null) return '';

      return html.replaceFirst(RegExp(r'<em.*<\/em>'), '');
    }

    final moreEs = document
            .getElementsByClassName('gen-search-form')
            .firstOrNull
            ?.getElementsByTagName('li') ??
        [];

    String? findMoreItemE(String key) {
      for (final itemE in moreEs) {
        if (itemE.innerHtml.contains(key)) {
          return itemE.innerHtml.replaceFirst(RegExp(r'<em.*<\/em>'), '');
        }
      }
      return null;
    }

    anime.area = findMoreItemE('地区：') ?? anime.area;
    anime.premiereTime =
        RegexpUtil.extractDate(parseMoreItemValue(findMoreItemE('上映：'))) ??
            anime.premiereTime;
    anime.playStatus =
        PlayStatus.text2PlayStatus(findMoreItemE('状态：') ?? '').text;
    anime.animeDesc = findMoreItemE('简介：') ?? anime.animeDesc;
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
    String url = baseUrl + "/index.php/vod/search.html?wd=$keyword";
    final document = await dioGetAndParse(url);
    if (document == null) return [];
    List<Anime> animes = [];

    final listEs = document.getElementsByClassName('search-list');
    for (final itemE in listEs) {
      String? coverUrl =
          itemE.getElementsByTagName('img').firstOrNull?.attributes['data-src'];
      if (coverUrl == null) continue;
      if (coverUrl.startsWith('//')) coverUrl = 'https:$coverUrl';
      coverUrl = coverUrl.replaceFirst(RegExp(r'.*url='), '');

      String? name = itemE
          .getElementsByClassName('slide-info-title')
          .firstOrNull
          ?.innerHtml;
      if (name == null) continue;

      String? detailUrl = itemE
          .getElementsByClassName('detail-info')
          .firstOrNull
          ?.getElementsByTagName('a')
          .firstOrNull
          ?.attributes['href'];
      if (detailUrl == null) continue;
      if (!detailUrl.startsWith('http')) detailUrl = baseUrl + detailUrl;

      animes.add(
        Anime(
          animeName: name,
          animeCoverUrl: coverUrl,
          animeUrl: detailUrl,
        ),
      );
    }

    return animes;
  }
}
