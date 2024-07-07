import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/models/week_record.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

class ClimbQdm with Climb {
  // 单例
  static final ClimbQdm _instance = ClimbQdm._();
  factory ClimbQdm() => _instance;
  ClimbQdm._();

  @override
  String get idName => "qdm";

  @override
  String get defaultBaseUrl => "https://www.qdm66.com";

  @override
  String get sourceName => "趣动漫";

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    String url = baseUrl + "/search/-------------.html?wd=$keyword";
    List<Anime> climbAnimes = [];

    var document = await dioGetAndParse(url);
    if (document == null) {
      return [];
    }

    var coverElements = document.getElementsByClassName("myui-vodlist__thumb");
    var nameElements = document.getElementsByClassName("searchkey");

    for (int i = 0; i < coverElements.length; ++i) {
      var coverElement = coverElements[i];
      var nameElement = nameElements[i];
      String animeUrl = nameElement.attributes["href"] ?? "";
      if (animeUrl.isNotEmpty) {
        // 添加前缀
        animeUrl = "$baseUrl$animeUrl";
      }

      climbAnimes.add(Anime(
          animeName: nameElement.innerHtml,
          animeEpisodeCnt: 0,
          animeCoverUrl: coverElement.attributes["data-original"] ?? "",
          animeUrl: animeUrl));
    }

    return climbAnimes;
  }

  @override
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    var document = await dioGetAndParse(anime.animeUrl);
    if (document == null) {
      return anime;
    }

    // 获取封面
    anime.animeCoverUrl = document
            .getElementsByClassName("lazyload")[0]
            .attributes["data-original"] ??
        anime.animeCoverUrl;

    // 获取首播时间
    anime.premiereTime = document
        .getElementsByClassName("text-muted hidden-xs")[1]
        .nextElementSibling!
        .innerHtml
        .trim();

    // 获取地区
    anime.area = document
        .getElementsByClassName("text-muted hidden-xs")[0]
        .nextElementSibling!
        .innerHtml;

    // 获取类别
    anime.category = document
        .getElementsByClassName("text-muted hidden-xs")[0]
        .previousElementSibling!
        .previousElementSibling!
        .innerHtml;

    // JOJO的奇妙冒险 第六部(石之海)Part.3：全集 / 2022-12-03
    // 海贼王：更新至1046集 / 2023-01-08
    // JOJO的奇妙冒险星尘斗士埃及篇：完结 / 2021-07-01
    // 熊熊勇闯异世界 第二季：第二季制作确定 / 2020-12-25
    // 天使降临到了我身边 新作动画：PV / 2021-02-07
    // 天使降临到了我身边OVA：HD / 2020-12-08
    String updateHtml =
        document.getElementsByClassName("data hidden-sm")[0].innerHtml;
    // updateHtml例子：<span class="text-muted">更新：</span><span class="text-red">更新至1046集  /  2023-01-08 </span>
    // 获取最新集数和状态
    // 缺点：如果动漫完结，则无法直接找到集数
    if (updateHtml.contains("完结") || updateHtml.contains("全集")) {
      anime.playStatus = "已完结";
      // 集数通过第1个播放列表中的元素个数来获取
      anime.animeEpisodeCnt = document
              .getElementById("playlist1")
              ?.getElementsByTagName("li")
              .length ??
          anime.animeEpisodeCnt;
    } else if (updateHtml.contains("更新至")) {
      anime.playStatus = "连载中";
      String episodeCntStr =
          RegExp("更新至[0-9]*").stringMatch(updateHtml).toString();
      episodeCntStr = episodeCntStr.substring(3);
      anime.animeEpisodeCnt = int.parse(episodeCntStr);
    } else {
      anime.playStatus = "";
    }

    if (showMessage) ToastUtil.showText("更新完毕");

    return anime;
  }

  @override
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) async {
    return [];
  }

  @override
  Future<List<List<WeekRecord>>> climbWeeklyTable() async {
    var document = await dioGetAndParse(baseUrl);
    if (document == null) {
      return [];
    }

    List<List<WeekRecord>> weeks = [];
    for (int weekday = 1; weekday <= 7; weekday++) {
      List<WeekRecord> records = [];
      var lis = document
          .getElementsByClassName("mod")[weekday - 1]
          .getElementsByTagName("li");
      for (var li in lis) {
        Anime anime = Anime(animeName: "");
        var a = li.getElementsByTagName("a")[0];
        anime.animeName = a.innerHtml;
        anime.animeUrl = "$baseUrl${a.attributes['href']}";
        String info = li.getElementsByTagName("span")[0].innerHtml;

        WeekRecord weekRecord = WeekRecord(anime: anime, info: info);
        records.add(weekRecord);
      }
      weeks.add(records);
    }
    return weeks;
  }
}
