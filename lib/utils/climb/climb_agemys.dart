import 'dart:math';

import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/anime_filter.dart';
import 'package:animetrace/models/params/page_params.dart';
import 'package:animetrace/models/week_record.dart';
import 'package:animetrace/utils/climb/climb.dart';
import 'package:animetrace/utils/climb/climb_yhdm.dart';
import 'package:html/dom.dart';

class ClimbAgemys with Climb {
  // 单例
  static final ClimbAgemys _instance = ClimbAgemys._();
  factory ClimbAgemys() => _instance;
  ClimbAgemys._();

  @override
  String get idName => "age";

  @override
  String get defaultBaseUrl => "https://www.agedm.vip";

  @override
  String get sourceName => "AGE动漫";

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    String url = baseUrl + "/search?query=$keyword";

    final document = await dioGetAndParse(url);
    if (document == null) return [];

    return _parseAnimeList(document);
  }

  @override
  Future<Anime> climbAnimeInfo(Anime anime) async {
    var document = await dioGetAndParse(anime.animeUrl);
    if (document == null) return anime;

    var detailImformValues =
        document.getElementsByClassName("detail_imform_value");
    anime.area = detailImformValues[0].innerHtml;
    anime.category = detailImformValues[1].innerHtml;
    anime.nameOri = detailImformValues[2].innerHtml;
    anime.nameAnother = detailImformValues[3].innerHtml;
    anime.authorOri = detailImformValues[4].innerHtml;
    anime.productionCompany = detailImformValues[5].innerHtml;
    anime.premiereTime = detailImformValues[6].innerHtml;
    anime.playStatus = detailImformValues[7].innerHtml;

    String desc =
        document.getElementsByClassName("video_detail_desc")[0].innerHtml;
    anime.animeDesc = desc.replaceAll("<br>", "\n");
    anime.animeCoverUrl = document
        .getElementsByClassName("video_detail_cover")[0]
        .getElementsByTagName("img")[0]
        .attributes["data-original"]!;

    // 集数：从所有播放列表中选择最大的
    // 如果播放列表中有PV，直接跳过看下一个播放列表
    // 如果有全集，直接返回1
    // 然后获取播放列表的长度
    List<int> episodeNumbers = [];
    var uls = document.getElementsByClassName("video_detail_episode");
    for (var ul in uls) {
      var lis = ul.getElementsByTagName("li");
      if (lis.isNotEmpty) {
        String first = lis[0].getElementsByTagName("a")[0].innerHtml;
        if (first.contains("PV")) {
          continue;
        } else if (first.contains("全集")) {
          anime.animeEpisodeCnt = 1;
          break;
        } else {
          // 最后一话可能是OVA3或OAD，而不是第xx集，所以获取长度而非OVA
          episodeNumbers.add(ul.getElementsByTagName("li").length);
        }
      } else {
        // 播放列表是空的，此时不添加到episodeNumbers
      }
    }
    if (episodeNumbers.isNotEmpty) {
      anime.animeEpisodeCnt =
          episodeNumbers.reduce((value, element) => max(value, element));
    }

    return anime;
  }

  @override
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) async {
    final pageIndex = pageParams.getFixedPageIndex(firstPageIndex: 1);
    String parseArg(String arg) => arg.isEmpty ? 'all' : arg;
    String url = baseUrl +
        '/catalog/${parseArg(filter.category)}-${parseArg(filter.year)}-all-all-all-time-$pageIndex-${parseArg(filter.region)}-${parseArg(filter.season)}-${parseArg(filter.status)}';
    final document = await dioGetAndParse(url);
    if (document == null) return [];

    return _parseAnimeList(document);
  }

  Future<List<WeekRecord>> climbWeeklyTableItem(int weekday) async {
    var document = await dioGetAndParse(baseUrl);
    if (document == null) {
      return [];
    }

    List<WeekRecord> records = [];
    if (weekday == 7) weekday = 0;
    final weekPane = document.getElementById("week-$weekday-pane");
    if (weekPane == null) return [];

    final lis = weekPane.getElementsByTagName('li');
    for (var li in lis) {
      final info = li.getElementsByClassName('title_sub').first.innerHtml;
      final anime = Anime(animeName: "");
      anime.animeName = li.getElementsByTagName('a').first.innerHtml;
      anime.animeUrl =
          li.getElementsByTagName('a').first.attributes['href'] ?? '';

      WeekRecord weekRecord = WeekRecord(anime: anime, info: info);
      records.add(weekRecord);
    }

    return records;
  }

  List<Anime> _parseAnimeList(Document document) {
    List<Anime> animes = [];
    var elements = document.getElementsByClassName("cata_video_item");

    for (var element in elements) {
      String? coverUrl =
          element.getElementsByTagName("img")[0].attributes["data-original"];
      String? animeName =
          element.getElementsByTagName("img")[0].attributes["alt"];
      String? animeUrl =
          element.getElementsByTagName("a")[0].attributes["href"];
      String? episodeCntStr =
          element.getElementsByClassName("video_play_status")[0].innerHtml;
      String? premiereTime = element
          .getElementsByClassName("video_detail_info")[3]
          .innerHtml
          .replaceFirst(RegExp(r'<span.*<\/span>'), '');
      // AGE动漫的集表示和樱花动漫的一致，因此也使用这个解析
      int episodeCnt = ClimbYhdm.parseEpisodeCntOfyhdm(episodeCntStr);
      if (coverUrl != null) {
        if (coverUrl.startsWith("//")) coverUrl = "https:$coverUrl";
      }
      animes.add(Anime(
        animeName: animeName ?? "",
        animeEpisodeCnt: episodeCnt,
        animeCoverUrl: coverUrl ?? "",
        animeUrl: animeUrl?.replaceFirst("http://", "https://") ?? "",
        premiereTime: premiereTime,
      ));
    }
    return animes;
  }
}
