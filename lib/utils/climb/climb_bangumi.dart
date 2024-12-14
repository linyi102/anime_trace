import 'package:darty_json/darty_json.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/bangumi/bangumi.dart';
import 'package:flutter_test_future/models/enum/play_status.dart';
import 'package:flutter_test_future/models/week_record.dart';
import 'package:flutter_test_future/repositories/bangumi_repository.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/site_collection_tab.dart';
import 'package:flutter_test_future/utils/climb/user_collection.dart';
import 'package:flutter_test_future/utils/dio_util.dart';
import 'package:flutter_test_future/utils/network/bangumi_api.dart';
import 'package:flutter_test_future/utils/time_util.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:html/dom.dart';

class ClimbBangumi with Climb {
  // 单例
  static final ClimbBangumi _instance = ClimbBangumi._();
  factory ClimbBangumi() => _instance;
  ClimbBangumi._();

  final repository = BangumiRepository();

  @override
  String get idName => "bangumi";

  @override
  String get defaultBaseUrl => "https://bangumi.tv";

  @override
  String get sourceName => "Bangumi";

  @override
  List<SiteCollectionTab> get siteCollectionTabs => [
        SiteCollectionTab(title: "想看", word: "wish"),
        SiteCollectionTab(title: "看过", word: "collect"),
        SiteCollectionTab(title: "在看", word: "do"),
        SiteCollectionTab(title: "搁置", word: "on_hold"),
        SiteCollectionTab(title: "放弃", word: "dropped"),
      ];

  @override
  String get userCollBaseUrl => "$baseUrl/anime/list";

  @override
  int get userCollPageSize => 24;

  /// 根据关键字搜索相关动漫(只需获取名字、封面链接、详细网址，之后会通过详细网址来获取其他信息)
  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    String url = baseUrl +
        "/subject_search/$keyword?cat=${Config.selectedBangumiSearchCategoryKey}";
    List<Anime> climbAnimes = [];

    final document = await dioGetAndParse(url, headers: BangumiApi.headers);
    if (document == null) return [];

    climbAnimes = parseAnimeListByBrowserItemList(document);
    return climbAnimes;
  }

  String _parseBangumiSubjectId(String url) {
    final match = RegExp(r'subject\/[0-9]*').firstMatch(url);
    if (match == null) return '';
    return match[0]?.replaceFirst('subject/', '') ?? '';
  }

  /// 爬取动漫详细信息
  @override
  Future<Anime> climbAnimeInfo(Anime anime) async {
    final subjectId = _parseBangumiSubjectId(anime.animeUrl);
    final bgmSubject = await repository.fetchSubject(subjectId);
    if (bgmSubject == null) return anime;

    anime.animeCoverUrl = bgmSubject.images?.large ?? anime.animeCoverUrl;
    anime.animeDesc = bgmSubject.summary ?? anime.animeDesc;
    anime.premiereTime =
        TimeUtil.getYMDByDateTime(bgmSubject.date, delimiter: '-');
    anime.category = bgmSubject.platform ?? anime.category;

    final allEpisodes = await repository.fetchEpisodes(subjectId);
    final needEpisodeTypeValues = [
      BgmEpisodeType.main.value,
      BgmEpisodeType.sp.value
    ];
    final now = DateTime.now();
    final episodes = allEpisodes
        .where((episode) => needEpisodeTypeValues.contains(episode.type));
    final playedEpisodes =
        episodes.where((episode) => episode.airdate?.isBefore(now) ?? false);
    if (allEpisodes.length >= repository.episodesLimit) {
      anime.playStatus = PlayStatus.unknown.text;
    } else {
      anime.animeEpisodeCnt = playedEpisodes.length;
      anime.playStatus = playedEpisodes.isEmpty
          ? PlayStatus.notStarted.text
          : playedEpisodes.length < episodes.length
              ? PlayStatus.playing.text
              : PlayStatus.finished.text;
    }

    return anime;
  }

  /// 查询是否存在该用户
  @override
  Future<bool> existUser(String userId) async {
    String url = "$userCollBaseUrl/$userId";

    var document = await dioGetAndParse(url);
    if (document == null) return false;

    // <div class="message">
    // <h2>呜咕，出错了</h2>
    // <p class="text">数据库中没有查询到该用户的信息</p>
    if (document.getElementsByClassName("message").isNotEmpty) return false;

    return true;
  }

  /// 查询用户某个收藏下的列表
  @override
  Future<UserCollection> climbUserCollection(
      String userId, SiteCollectionTab siteCollectionTab,
      {int page = 1}) async {
    String url =
        "$userCollBaseUrl/$userId/${siteCollectionTab.word}?page=$page";

    UserCollection userCollection = UserCollection(totalCnt: 0, animes: []);
    var document = await dioGetAndParse(url);
    if (document == null) {
      return userCollection;
    }

    // 获取该tab动漫数量
    // <li><a href="/anime/list/509755/wish" ><span>想看        (44)</span></a></li>                        <li><a href="/anime/list/509755/collect" class="focus"><span>看过        (138)</span></a></li>                        <li><a href="/anime/list/509755/do" ><span>在看        (56)</span></a></li>                        <li><a href="/anime/list/509755/on_hold" ><span>搁置        (6)</span></a></li>                        <li><a href="/anime/list/509755/dropped" ><span>抛弃        (1)</span></a></li>        </ul>
    // 懒惰匹配 wish.*?\([0-9]*\)
    // 可以匹配到 wish" ><span>想看        (44)
    var navSubTabs = document.getElementsByClassName("navSubTabs")[0];
    var str = RegExp("${siteCollectionTab.word}.*?\\([0-9]*\\)")
        .firstMatch(navSubTabs.innerHtml)?[0];
    if (str != null) {
      str = str.substring(str.indexOf("(") + 1, str.indexOf(")"));
      userCollection.totalCnt = int.tryParse(str) ?? 0;
    }

    // 在原来基础上添加(加载更多)，所以使用addAll，而非赋值
    userCollection.animes.addAll(parseAnimeListByBrowserItemList(document));
    return userCollection;
  }

  List<Anime> parseAnimeListByBrowserItemList(Document document) {
    var lis =
        document.getElementById("browserItemList")?.getElementsByTagName("li");
    if (lis == null || lis.isEmpty) {
      return [];
    }

    List<Anime> animes = [];
    // 获取该页动漫列表
    for (var li in lis) {
      String detailUrl =
          li.getElementsByTagName("a")[0].attributes["href"] ?? "";
      String animeUrl = "$baseUrl$detailUrl";

      var imgElements = li.getElementsByTagName("img");
      String img = "";
      // 有些没有封面，例如魔法科高校的劣等生 续篇
      if (imgElements.isNotEmpty) img = imgElements[0].attributes["src"] ?? "";
      if (!img.startsWith("https:")) img = "https:$img";

      var inner = li.getElementsByClassName("inner")[0];
      String name = inner.getElementsByTagName("a")[0].innerHtml;
      var smallEs = inner.getElementsByTagName("small");
      String nameAnother = "";
      if (smallEs.isNotEmpty) nameAnother = smallEs.first.innerHtml;

      String tempInfo =
          inner.getElementsByClassName("info tip")[0].innerHtml.trim();

      Anime anime = Anime(
        animeName: name,
        nameAnother: nameAnother,
        animeCoverUrl: img,
        animeUrl: animeUrl,
        tempInfo: tempInfo,
      );
      animes.add(anime);
    }

    return animes;
  }

  @override
  Future<List<List<WeekRecord>>> climbWeeklyTable() async {
    final resp = await DioUtil.get(
      BangumiApi.calendar,
      headers: BangumiApi.headers,
    );
    if (resp.isFailure || resp.data.data is! List) return [];

    final json = Json.fromList(resp.data.data);
    List<List<WeekRecord>> weeks = [];
    for (final Json week in json.listValue) {
      List<WeekRecord> records = [];
      for (final Json item in week.mapValue['items']?.listValue ?? []) {
        String name = item.mapObjectValue['name_cn'] ?? '';
        if (name.isEmpty) name = item.mapObjectValue['name'] ?? '';
        String detailUrl = item.mapObjectValue['url'] ?? '';
        detailUrl = detailUrl.replaceFirst('bgm.tv', 'bangumi.tv');

        records.add(WeekRecord(
          anime: Anime(
            animeName: name,
            animeCoverUrl:
                item.mapValue['images']?.mapObjectValue['common'] ?? '',
            animeUrl: detailUrl,
          ),
          info: item.mapObjectValue['name'] ?? '',
        ));
      }
      weeks.add(records);
    }
    return weeks;
  }
}
