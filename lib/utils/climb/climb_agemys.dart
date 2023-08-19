import 'dart:math';

import 'package:flutter_test_future/models/age_record.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/week_record.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/climb_yhdm.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/utils/log.dart';

class ClimbAgemys extends Climb {
  // 单例
  static final ClimbAgemys _instance = ClimbAgemys._();
  factory ClimbAgemys() => _instance;
  ClimbAgemys._();

  @override
  String get baseUrl =>
      // "https://www.agemys.cc";
      // "https://www.agemys.net"; // 2022.10.27
      // "https://www.agemys.vip"; // 2023.04.19
      "https://age.tv"; // 2023.07.02

  @override
  String get sourceName => "AGE动漫";

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword,
      {bool showMessage = true}) async {
    String url = baseUrl + "/search?query=$keyword";

    var document = await dioGetAndParse(url);
    if (document == null) {
      return [];
    }

    List<Anime> climbAnimes = [];
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
      int episodeCnt = ClimbYhdm.parseEpisodeCntOfyhdm(
          episodeCntStr); // AGE动漫的集表示和樱花动漫的一致，因此也使用这个解析
      if (coverUrl != null) {
        if (coverUrl.startsWith("//")) coverUrl = "https:$coverUrl";
      }

      Anime climbAnime = Anime(
        animeName: animeName ?? "",
        animeEpisodeCnt: episodeCnt,
        animeCoverUrl: coverUrl ?? "",
        animeUrl: animeUrl ?? "",
      );
      Log.info("爬取封面：$coverUrl");
      Log.info("爬取动漫网址：${climbAnime.animeUrl}");
      climbAnimes.add(climbAnime);
    }
    Log.info("解析完毕√");
    return climbAnimes;
  }

  @override
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    var document = await dioGetAndParse(anime.animeUrl);
    if (document == null) {
      return anime;
    }

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

    if (showMessage) ToastUtil.showText("更新完毕");

    return anime;
  }

  @override
  Future<List<WeekRecord>> climbWeeklyTable(int weekday) async {
    var document = await dioGetAndParse(baseUrl);
    if (document == null) {
      return [];
    }

    List<WeekRecord> records = [];
    String script = document
        .getElementById("new_anime_page")!
        .nextElementSibling!
        .innerHtml;

    // \[.*\]
    RegExp regExp = RegExp("\\[.*\\]");
    String jsonStr = regExp.stringMatch(script).toString();
    List<AgeRecord> ageRecords = ageRecordFromJson(jsonStr);
    for (var ageRecord in ageRecords) {
      // 跳过不是该天的
      if (ageRecord.wd != weekday) continue;

      Anime anime = Anime(animeName: "");
      anime.animeName = ageRecord.name;
      anime.animeUrl = "$baseUrl/detail/${ageRecord.id}";

      String info = ageRecord.namefornew;
      if (ageRecord.isnew) {
        info += " new!";
      }

      WeekRecord weekRecord = WeekRecord(anime: anime, info: info);
      records.add(weekRecord);
    }

    return records;
  }
}
