import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/anime_filter.dart';
import 'package:animetrace/models/params/page_params.dart';
import 'package:animetrace/models/params/result.dart';
import 'package:animetrace/utils/climb/climb.dart';
import 'package:animetrace/utils/climb/site_collection_tab.dart';
import 'package:animetrace/utils/climb/user_collection.dart';
import 'package:animetrace/utils/dio_util.dart';
import 'package:animetrace/utils/regexp.dart';
import 'package:darty_json/darty_json.dart';
import 'package:html/dom.dart';

class ClimbDouban with Climb {
  // 单例
  static final ClimbDouban _instance = ClimbDouban._();
  factory ClimbDouban() => _instance;
  ClimbDouban._();

  @override
  String get idName => "douban";

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
  Future<Anime> climbAnimeInfo(Anime anime) async {
    var document = await dioGetAndParse(anime.animeUrl);
    if (document == null) return anime;

    var mainpicElement = document.getElementById("mainpic");
    anime.animeCoverUrl =
        mainpicElement?.getElementsByTagName("img")[0].attributes["src"] ?? "";

    anime.animeName = document
        .getElementsByTagName("h1")[0]
        .getElementsByTagName("span")[0]
        .innerHtml;

    // 简介
    final intraEl = document.getElementById('link-report-intra');
    if (intraEl != null) {
      for (final el in intraEl.children) {
        if (el.attributes['property'] == 'v:summary') {
          anime.animeDesc =
              el.innerHtml.split('<br>').map((e) => e.trim()).join('\n');
          break;
        }
      }
    }

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
        if (innerHtml.contains(RegExp('上映日期|首播'))) {
          anime.premiereTime =
              RegexpUtil.extractDate(plElement.nextElementSibling?.innerHtml) ??
                  '';
        } else if (innerHtml.contains("作者")) {
          anime.authorOri = plElement.nextElementSibling?.innerHtml ?? "";
        }
      }
    }
    return anime;
  }

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    List<Anime> animes = [];
    keyword = keyword.replaceAll(" ", "+"); // 网页搜索时输入空格会被替换为加号

    Result result = await DioUtil.get(
      'https://m.douban.com/rexxar/api/v2/search?q=$keyword&type=&loc_id=&start=0&count=10&sort=relevance',
      referer: 'https://www.douban.com/search',
    );

    final json = Json.fromDynamic(result.data.data);
    if (json.exception != null) return [];

    final items = [
      ...json['subjects']['items'].listOf<Map>() ?? [],
      ...json['smart_box'].listOf<Map>() ?? [],
    ];

    for (final item in items) {
      if (item['layout'] != 'subject' || item['target'] is! Map) continue;

      final target = item['target'];
      String? title = target['title'];
      String? coverUrl = target['cover_url'];
      String? detailId = target['id'];
      if (title == null || coverUrl == null || detailId == null) {
        continue;
      }

      coverUrl = coverUrl.replaceFirst(RegExp(r'h\/[0-9]+'), 'h/600');
      animes.add(
        Anime(
            animeName: title,
            animeCoverUrl: coverUrl,
            animeUrl: 'https://www.douban.com/subject/$detailId'),
      );
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

    return DioUtil.urlResponseOk(url);
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
