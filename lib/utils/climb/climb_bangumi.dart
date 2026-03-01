import 'package:animetrace/models/enum/anime_area.dart';
import 'package:animetrace/models/enum/anime_category.dart';
import 'package:darty_json/darty_json.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/bangumi/bangumi.dart';
import 'package:animetrace/models/enum/play_status.dart';
import 'package:animetrace/models/week_record.dart';
import 'package:animetrace/repositories/bangumi_repository.dart';
import 'package:animetrace/utils/climb/climb.dart';
import 'package:animetrace/utils/climb/site_collection_tab.dart';
import 'package:animetrace/utils/climb/user_collection.dart';
import 'package:animetrace/utils/dio_util.dart';
import 'package:animetrace/utils/network/bangumi_api.dart';
import 'package:animetrace/utils/time_util.dart';
import 'package:animetrace/values/values.dart';
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
        SiteCollectionTab(title: "想看", identity: 1),
        SiteCollectionTab(title: "看过", identity: 2),
        SiteCollectionTab(title: "在看", identity: 3),
        SiteCollectionTab(title: "搁置", identity: 4),
        SiteCollectionTab(title: "放弃", identity: 5),
      ];

  @override
  String get userCollBaseUrl => "$baseUrl/anime/list";

  @override
  int get userCollPageSize => 100;

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
    for (final area in AnimeArea.values) {
      if ((bgmSubject.metaTags ?? []).contains(area.label)) {
        anime.area = area.label;
        break;
      }
    }

    final allEpisodes = await repository.fetchEpisodes(subjectId);
    final needEpisodeTypeValues = [
      BgmEpisodeType.main.value,
      BgmEpisodeType.sp.value
    ];
    final now = DateTime.now();
    final episodes = allEpisodes
        .where((episode) => needEpisodeTypeValues.contains(episode.type))
        // 去除 type=0 的 sort=*.5 的特殊集。type=1 (sp) 正常解析
        // 例如：名侦探柯南 ep 762.5 sort 762.5 type 0
        .where((episode) => !(episode.type == BgmEpisodeType.main.value &&
            episode.sort.toString().endsWith('.5')));
    final playedEpisodes =
        episodes.where((episode) => episode.airdate?.isBefore(now) ?? false);

    anime.animeEpisodeCnt = playedEpisodes.length;
    anime.playStatus = playedEpisodes.isEmpty
        ? PlayStatus.notStarted.text
        : playedEpisodes.length < episodes.length
            ? PlayStatus.playing.text
            : PlayStatus.finished.text;

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
    String userId,
    SiteCollectionTab siteCollectionTab, {
    int page = 1,
  }) async {
    final collection = UserCollection(totalCnt: 0, animes: []);

    final r = await repository.fetchCollections(
        username: userId,
        type: siteCollectionTab.identity,
        pageNo: page - 1,
        pageSize: userCollPageSize);
    collection.totalCnt = r.total;
    collection.animes = r.list.map((e) {
      String info = [
        if (e.date != null) TimeUtil.getYMDByDateTime(e.date!, delimiter: '-'),
        if (e.eps != null) '${e.eps.toString()} 集',
      ].join(' / ');

      final anime = Anime(
        animeName: (e.nameCn ?? '').isNotEmpty ? e.nameCn! : (e.name ?? ''),
        nameOri: e.name ?? '',
        animeCoverUrl: e.images?.medium ?? '',
        animeUrl: '$baseUrl/subject/${e.id}',
        premiereTime: e.date == null
            ? ''
            : TimeUtil.getYMDByDateTime(e.date!, delimiter: '-'),
        animeDesc: e.summary ?? '',
        tempInfo: info,
        animeEpisodeCnt: e.eps ?? 0,
      );

      for (final area in AnimeArea.values) {
        if ((e.metaTags ?? []).contains(area.label)) {
          anime.area = area.label;
          break;
        }
      }
      for (final category in AnimeCategory.values) {
        if ((e.metaTags ?? []).contains(category.label)) {
          anime.category = category.label;
          break;
        }
      }

      return anime;
    }).toList();

    return collection;
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
      String nameAnother = inner
              .getElementsByTagName("h3")
              .elementAtOrNull(0)
              ?.getElementsByTagName("small")
              .elementAtOrNull(0)
              ?.innerHtml ??
          '';

      String tempInfo =
          inner.getElementsByClassName("info tip")[0].innerHtml.trim();
      String premiereTime = (RegExp(r'(\d{4}[年\-]\d{1,2}[月\-]\d{1,2}[日]?)')
                  .firstMatch(tempInfo)
                  ?.group(0) ??
              '')
          .replaceAll('年', '-')
          .replaceAll('月', '-')
          .replaceAll('日', '')
          .split('-')
          .map((e) => e.padLeft(2, '0'))
          .join('-');

      Anime anime = Anime(
        animeName: name,
        nameAnother: nameAnother,
        animeCoverUrl: img,
        animeUrl: animeUrl,
        tempInfo: tempInfo,
        premiereTime: premiereTime,
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
        detailUrl = detailUrl.replaceFirst('http:', 'https:');

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
