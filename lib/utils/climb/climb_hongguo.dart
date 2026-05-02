import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/enum/anime_area.dart';
import 'package:animetrace/models/enum/play_status.dart';
import 'package:animetrace/utils/climb/climb.dart';

class ClimbHongguo with Climb {
  @override
  String get idName => "hongguo";

  @override
  String get defaultBaseUrl => "https://www.hongguostudio.com";

  @override
  String get sourceName => "红果";

  @override
  Future<Anime> climbAnimeInfo(Anime anime) async {
    final document = await dioGetAndParse(anime.animeUrl);
    if (document == null) return anime;

    final cover = document
            .getElementsByClassName('hl-item-thumb')
            .firstOrNull
            ?.attributes['data-original'] ??
        '';
    if (cover.isNotEmpty) {
      anime.animeCoverUrl = cover;
    }

    final infoEls = document
            .getElementsByClassName('hl-vod-data')
            .firstOrNull
            ?.getElementsByTagName('li') ??
        [];

    String? extractInfoValue(String label) {
      for (final infoEl in infoEls) {
        final emEl = infoEl.getElementsByTagName('em').firstOrNull;
        if (emEl?.innerHtml.contains(label) == true) {
          return emEl?.nextElementSibling == null
              ? RegExp('</em>(.+)').firstMatch(infoEl.innerHtml)?.group(1)
              : emEl?.nextElementSibling?.innerHtml;
        }
      }
      return null;
    }

    anime.premiereTime = extractInfoValue('年份') ?? anime.premiereTime;
    anime.playStatus =
        PlayStatus.text2PlayStatus(extractInfoValue('状态') ?? '').text;
    anime.animeDesc = extractInfoValue('简介') ?? anime.animeDesc;
    anime.area =
        AnimeArea.parse(extractInfoValue('地区') ?? '')?.label ?? anime.area;
    anime.animeEpisodeCnt = document
            .getElementsByClassName('hl-plays-list')
            .firstOrNull
            ?.getElementsByTagName('li')
            .length ??
        anime.animeEpisodeCnt;

    return anime;
  }

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    String url = baseUrl + "/vodsearch/-------------.html?wd=$keyword";
    final document = await dioGetAndParse(url);
    if (document == null) return [];

    List<Anime> animes = [];
    final liEs = document
            .getElementsByClassName('hl-one-list')
            .firstOrNull
            ?.getElementsByTagName('li') ??
        [];
    for (final liEl in liEs) {
      final imgEl = liEl
              .getElementsByClassName('hl-item-thumb')
              .firstOrNull
              ?.attributes['data-original'] ??
          '';
      final aEl = liEl
          .getElementsByClassName('hl-item-title')
          .firstOrNull
          ?.getElementsByTagName('a')
          .firstOrNull;
      if (aEl == null) continue;

      final url = '$baseUrl${aEl.attributes['href']}';

      final name = aEl.innerHtml;
      if (name.isEmpty) continue;

      animes.add(Anime(
        animeName: name,
        animeCoverUrl: imgEl,
        animeUrl: url,
      ));
    }
    return animes;
  }
}
