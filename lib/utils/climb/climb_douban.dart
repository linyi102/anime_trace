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
        SiteCollectionTab(title: "在看", identity: "do"),
        SiteCollectionTab(title: "想看", identity: "wish"),
        SiteCollectionTab(title: "看过", identity: "collect"),
      ];

  @override
  String get userCollBaseUrl => "https://movie.douban.com/people";

  @override
  int get userCollPageSize => 15;

  @override
  Future<Anime> climbAnimeInfo(Anime anime) async {
    final idMatch = RegExp(r'subject/(\d+)').firstMatch(anime.animeUrl);
    if (idMatch == null) return anime;

    final subjectId = idMatch.group(1)!;

    final result = await DioUtil.get(
      'https://m.douban.com/rexxar/api/v2/subject/$subjectId',
      referer: 'https://www.douban.com/search',
    );

    final json = Json.fromDynamic(result.data.data);
    if (json.exception != null) return anime;

    // 基础信息
    anime.animeName = json['title'].string ?? anime.animeName;
    anime.animeDesc = json['intro'].string ?? '';
    anime.animeCoverUrl = json['cover_url'].string ??
        json['pic']['large'].string ??
        anime.animeCoverUrl;

    // 集数
    anime.animeEpisodeCnt =
        json['episodes_count'].integer ?? anime.animeEpisodeCnt;

    // 首播时间
    final pubdates = json['pubdate'].listOf<String>();
    if (pubdates != null && pubdates.isNotEmpty) {
      // 例如：2014-04-04(日本)
      anime.premiereTime = RegexpUtil.extractDate(pubdates.first) ?? '';
    } else {
      anime.premiereTime = json['year'].string ?? '';
    }

    // 地区
    final countries = json['countries'].listOf<String>();
    if (countries != null && countries.isNotEmpty) {
      anime.area = countries.first;
    }

    // 别名
    final akaList = json['aka'].listOf<String>();
    if (akaList != null && akaList.isNotEmpty) {
      anime.nameAnother = akaList.join(' / ');
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
      String? premiereTime = target['year'];
      if (title == null || coverUrl == null || detailId == null) {
        continue;
      }

      coverUrl = coverUrl.replaceFirst(RegExp(r'h\/[0-9]+'), 'h/600');
      animes.add(
        Anime(
          animeName: title,
          animeCoverUrl: coverUrl,
          animeUrl: 'https://www.douban.com/subject/$detailId',
          premiereTime: premiereTime ?? '',
        ),
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
        "$userCollBaseUrl/$userId/${siteCollectionTab.identity}?start=${(page - 1) * userCollPageSize}";

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
