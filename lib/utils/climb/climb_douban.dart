import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/site_collection_tab.dart';
import 'package:flutter_test_future/utils/climb/user_collection.dart';
import 'package:flutter_test_future/utils/dio_package.dart';
import 'package:html/dom.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

class ClimbDouban extends Climb {
  // 单例
  static final ClimbDouban _instance = ClimbDouban._();
  factory ClimbDouban() => _instance;
  ClimbDouban._();

  @override
  String get baseUrl => "https://www.douban.com";

  @override
  String get sourceName => "豆瓣";

  @override
  List<SiteCollectionTab> get siteCollectionTabs => [
        SiteCollectionTab(title: "在看", word: "do"),
        SiteCollectionTab(title: "想看", word: "wish"),
        SiteCollectionTab(title: "看过", word: "collect"),
      ];

  @override
  String get userCollBaseUrl => "https://movie.douban.com/people";

  @override
  int get userCollPageSize => 15;

  @override
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    var document = await dioGetAndParse(anime.animeUrl);
    if (document == null) {
      return anime;
    }

    var mainpicElement = document.getElementById("mainpic");
    anime.animeCoverUrl =
        mainpicElement?.getElementsByTagName("img")[0].attributes["src"] ?? "";

    anime.animeName = document
        .getElementsByTagName("h1")[0]
        .getElementsByTagName("span")[0]
        .innerHtml;

    var infoElement = document.getElementById("info");
    // Log.info("infoElement.innerHtml=${infoElement?.innerHtml}");
    RegExp(r'<span class="pl">.*<br')
        .allMatches(infoElement?.innerHtml ?? "")
        .forEach((regExpMatch) {
      String line = regExpMatch[0] ?? "";
      // 集数可能不止2位数，因此通过以下方式定位。其他同理
      // start+2是为了跳过"> "
      int start = line.lastIndexOf("> ") + 2, end = line.lastIndexOf("<br");
      if (line.contains("集数")) {
        // <span class="pl">集数:</span> 13<br
        // Log.info("集数=${line.substring(start, end)}");
        anime.animeEpisodeCnt = int.parse(line.substring(start, end));
      } else if (line.contains("又名")) {
        // Log.info("又名=${line.substring(start, end)}");
        anime.nameAnother = line.substring(start, end);
      } else if (line.contains("制片国家/地区")) {
        // Log.info("地区=${line.substring(start, end)}");
        anime.area = line.substring(start, end);
      }
    });

    if (infoElement != null) {
      var plElements = infoElement.getElementsByClassName("pl");
      for (var plElement in plElements) {
        String innerHtml = plElement.innerHtml;
        if (innerHtml.contains("首播")) {
          // 1997-02-23(日本)
          anime.premiereTime = plElement.nextElementSibling?.innerHtml ?? "";
          // 1997-02-23
          if (anime.premiereTime.contains("(")) {
            anime.premiereTime = anime.premiereTime.split("(")[0];
          }
        } else if (innerHtml.contains("作者")) {
          anime.authorOri = plElement.nextElementSibling?.innerHtml ?? "";
        }
      }
    }
    if (showMessage) ToastUtil.showText("更新完毕");

    return anime;
  }

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword,
      {bool showMessage = true}) async {
    List<Anime> animes = [];

    keyword = keyword.replaceAll(" ", "+"); // 网页搜索时输入空格会被替换为加号
    String url = "$baseUrl/search?q=$keyword";

    var document = await dioGetAndParse(url);
    if (document == null) {
      return [];
    }

    // 只获取第一个<div class="result-list">，也就是相关豆瓣内容，后面两个都是相关豆瓣用户和相关日记
    var h2Elements = document.getElementsByTagName("h2");
    bool existResult = false;
    for (var h2Element in h2Elements) {
      if (h2Element.innerHtml.contains("相关豆瓣内容")) {
        existResult = true;
      }
    }
    if (!existResult) return animes;

    var elements = document
        .getElementsByClassName("result-list")[0]
        .getElementsByClassName("result");
    for (var element in elements) {
      // Log.info("element=${element.innerHtml}");
      String coverUrl =
          element.getElementsByTagName("img")[0].attributes["src"] ?? "";
      String name = element
          .getElementsByTagName("h3")[0]
          .getElementsByTagName("a")[0]
          .innerHtml;
      String animeUrl =
          element.getElementsByClassName("nbg")[0].attributes["href"] ?? "";
      animeUrl = Uri.decodeComponent(animeUrl);
      animeUrl = animeUrl.split("&")[0];
      animeUrl = animeUrl.replaceAll("https://www.douban.com/link2/?url=", "");

      animes.add(Anime(
          animeName: name,
          animeEpisodeCnt: 0,
          animeCoverUrl: coverUrl,
          animeUrl: animeUrl));
    }

    return animes;
  }

  @override
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) async {
    return [];
  }

  /// 查询是否存在该用户
  @override
  Future<bool> existUser(String userId) async {
    String url = "$userCollBaseUrl/$userId";

    return DioPackage.urlResponseOk(url);
  }

  Future<int> climbUserCollectionCnt(Document document) async {
    // 例：埃路皮在看的电视剧(10)
    String? title = document
        .getElementById("db-usr-profile")
        ?.getElementsByTagName("h1")[0]
        .innerHtml;
    if (title == null) return 0;

    var allMatches = RegExp("\\([0-9]*\\)").allMatches(title);
    // (10)
    String str = allMatches.last[0].toString();
    int? cnt = int.tryParse(str.substring(1, str.length - 1));
    return cnt ?? 0;
  }

  /// 查询某个用户的收藏
  @override
  Future<UserCollection> climbUserCollection(
      String userId, SiteCollectionTab siteCollectionTab,
      {int page = 1}) async {
    String url =
        "$userCollBaseUrl/$userId/${siteCollectionTab.word}?start=${(page - 1) * userCollPageSize}";

    var document = await dioGetAndParse(url);
    if (document == null) {
      return UserCollection(totalCnt: 0, animes: []);
    }

    int totalCnt = await climbUserCollectionCnt(document);

    List<Anime> animes = [];
    var elements = document.getElementsByClassName("item");
    for (var element in elements) {
      String title = element
          .getElementsByClassName("info")[0]
          .getElementsByClassName("title")[0]
          .getElementsByTagName("a")[0]
          .innerHtml;
      String tempInfo = element.getElementsByClassName("intro")[0].innerHtml;
      title = title.replaceAll(RegExp("</?em>"), "");
      var titles = title.split("/");
      var names = [];
      for (var title in titles) {
        names.add(title.trim());
      }

      String img =
          element.getElementsByTagName("img")[0].attributes["src"] ?? "";
      String animeUrl = element
              .getElementsByClassName("title")[0]
              .getElementsByTagName("a")[0]
              .attributes["href"] ??
          "";

      Anime anime = Anime(
        animeName: names[0],
        nameAnother: names.skip(1).join(" / "),
        animeCoverUrl: img,
        animeUrl: animeUrl,
        tempInfo: tempInfo,
      );
      animes.add(anime);
    }

    return UserCollection(totalCnt: totalCnt, animes: animes);
  }
}
