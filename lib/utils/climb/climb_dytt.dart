import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/enum/anime_area.dart';
import 'package:animetrace/models/enum/play_status.dart';
import 'package:animetrace/utils/climb/climb.dart';

class ClimbDytt with Climb {
  @override
  String get idName => "dytt";

  @override
  String get defaultBaseUrl => "https://dyttzyw.com";

  @override
  String get sourceName => "电影天堂";

  @override
  Future<Anime> climbAnimeInfo(Anime anime) async {
    final document = await dioGetAndParse(anime.animeUrl);
    if (document == null) return anime;

    final cover = document
            .getElementsByClassName('w-full h-full rounded-lg shadow-md')
            .firstOrNull
            ?.attributes['src'] ??
        '';
    if (cover.isNotEmpty) {
      anime.animeCoverUrl = cover;
    }

    final trEls = document
            .getElementsByTagName('tbody')
            .firstOrNull
            ?.getElementsByTagName('tr') ??
        [];

    String? extractTdValue(String label) {
      for (final trEl in trEls) {
        final tdEls = trEl.getElementsByTagName('td');
        if (tdEls.elementAtOrNull(0)?.innerHtml == label) {
          return tdEls.elementAtOrNull(1)?.innerHtml;
        }
      }
      return null;
    }

    anime.premiereTime = extractTdValue('年代') ?? anime.premiereTime;
    anime.playStatus =
        PlayStatus.text2PlayStatus(extractTdValue('状态') ?? '').text;
    anime.area =
        AnimeArea.parse(extractTdValue('地区') ?? '')?.label ?? anime.area;
    anime.animeEpisodeCnt = document
            .getElementsByClassName('playlist')
            .firstOrNull
            ?.getElementsByClassName('border-b')
            .length ??
        anime.animeEpisodeCnt;
    anime.nameAnother = document
            .getElementsByClassName('italic text-orange-500')
            .firstOrNull
            ?.innerHtml ??
        anime.nameAnother;
    anime.animeDesc = document
            .getElementsByClassName('scrollbar-track-extra-grey')
            .firstOrNull
            ?.getElementsByTagName('p')
            .firstOrNull
            ?.innerHtml
            .replaceAll('<br>', '\n')
            .replaceAll(RegExp(r'(&nbsp;)+'), ' ') ??
        anime.animeDesc;

    return anime;
  }

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    String url = baseUrl + "/index.php/vod/search.html?wd=$keyword";
    final document = await dioGetAndParse(url);
    if (document == null) return [];

    List<Anime> animes = [];
    final trEls = document.getElementsByTagName('tr');
    for (final trEl in trEls) {
      final imgEl =
          trEl.getElementsByTagName('img').firstOrNull?.attributes['src'] ?? '';
      final aEl = trEl.getElementsByTagName('a').firstOrNull;
      if (aEl == null) continue;

      final url = '$baseUrl${aEl.attributes['href']}';

      final name = aEl
              .getElementsByClassName('font-medium')
              .firstOrNull
              ?.getElementsByTagName('div')
              .firstOrNull
              ?.innerHtml ??
          '';
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
