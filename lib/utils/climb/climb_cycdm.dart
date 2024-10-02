import 'dart:convert';

import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/dio_util.dart';
import 'package:flutter_test_future/utils/log.dart';

// 次元城动漫
class ClimbCycdm with Climb {
  // 单例
  static final ClimbCycdm _instance = ClimbCycdm._();
  factory ClimbCycdm() => _instance;
  ClimbCycdm._();

  @override
  String get idName => "cycdm";

  @override
  String get defaultBaseUrl => "https://www.cycanime.com";

  @override
  String get sourceName => "次元城动漫";

  bool isMobile = true;

  @override
  Future<Anime> climbAnimeInfo(Anime anime) async {
    var document = await dioGetAndParse(anime.animeUrl, isMobile: isMobile);
    if (document == null) return anime;

    var episodeBox = document.getElementsByClassName("anthology-list-box");
    if (episodeBox.isNotEmpty) {
      anime.animeEpisodeCnt = episodeBox[0].getElementsByTagName("li").length;
    }
    anime.animeCoverUrl = document
            .getElementsByClassName("lazy lazy1 mask-0")[0]
            .attributes["data-src"] ??
        anime.animeCoverUrl;
    anime.premiereTime = document
        .getElementsByClassName("slide-info-remarks")[1]
        .children[0]
        .innerHtml;
    anime.area = document
        .getElementsByClassName("slide-info-remarks")[2]
        .children[0]
        .innerHtml;
    anime.animeDesc = document.getElementsByClassName("text cor3")[0].innerHtml;
    if (anime.animeDesc == '暂无简介') anime.animeDesc = '';

    var lis = document
        .getElementsByClassName("drawer-scroll-list")[0]
        .getElementsByTagName("li");
    String dateLiInnerHtml =
        lis[8].innerHtml; // <em class="cor4">上映：</em>2021-01-09
    Log.info("dateLiInnerHtml=$dateLiInnerHtml");
    RegExp exp = RegExp("[0-9]{4}-[0-9]{2}-[0-9]{2}");
    anime.premiereTime =
        exp.stringMatch(dateLiInnerHtml).toString(); // 2021-01-09
    anime.playStatus = lis[1].getElementsByTagName("span")[0].innerHtml;
    return anime;
  }

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    String url = baseUrl + "/search.html?wd=$keyword";
    List<Anime> climbAnimes = [];

    var document = await dioGetAndParse(url, isMobile: isMobile);
    if (document == null) {
      return [];
    }

    var coverElements = document.getElementsByClassName("lazy");

    for (var element in coverElements) {
      String? coverUrl = element.attributes["data-src"];
      if (coverUrl != null) {
        if (coverUrl.startsWith("//")) coverUrl = "https:$coverUrl";
        climbAnimes.add(
            Anime(animeName: "", animeEpisodeCnt: 0, animeCoverUrl: coverUrl));
      }
    }

    var nameElements = document.getElementsByClassName("thumb-txt cor4 hide");
    var urlElements = document.getElementsByClassName("public-list-exp");

    for (int i = 0; i < nameElements.length; ++i) {
      climbAnimes[i].animeName = nameElements[i].innerHtml;
      // 获取网址
      String? animeUrl = urlElements[i].attributes["href"];
      climbAnimes[i].animeUrl = animeUrl == null ? "" : baseUrl + animeUrl;
    }
    return climbAnimes;
  }

  @override
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) async {
    return [];
  }

  /// 动漫链接：https://www.cycdm01.top/bangumi/3390.html
  /// 第4集：https://www.cycdm01.top/watch/3390/1/4.html
  @override
  Future<String> getVideoUrl(String animeUrl, int episodeNumber) async {
    String animeUrlWithoutHtml = animeUrl;
    // 提取出动漫id
    if (animeUrlWithoutHtml.endsWith('.html')) {
      animeUrlWithoutHtml =
          animeUrl.substring(0, animeUrl.length - '.html'.length);
    }
    // 播放路线
    int? urlId = int.tryParse(animeUrlWithoutHtml
        .substring(animeUrlWithoutHtml.lastIndexOf('/') + 1));
    if (urlId == null) return '';

    // 尝试获取播放线路
    int playRoute = await getPlayRoute(animeUrl) ?? 1;
    // 拼接该集的地址
    String episodeUrl = '$baseUrl/watch/$urlId/$playRoute/$episodeNumber.html';

    // 访问后获取到播放链接
    var document = await dioGetAndParse(episodeUrl);
    if (document == null) return '';

    String html = document.getElementsByClassName('player-box').first.innerHtml;
    String? urlLine = RegExp(r'"url":".*","url_next"').firstMatch(html)?[0];
    if (urlLine == null) return '';

    String base64DecodedPlayUrl = urlLine.substring(
        '"url":"'.length, urlLine.length - '","url_next"'.length);
    if (base64DecodedPlayUrl.isEmpty) return '';

    String playUrl = Uri.decodeFull(
        String.fromCharCodes(base64Decode(base64DecodedPlayUrl)));

    // 访问https://player.cycdm01.top/?url=xxx解析必要参数
    document = await dioGetAndParse(
        '${baseUrl.replaceFirst('www', 'player')}/?url=$playUrl');
    if (document == null) return '';

    html = document.getElementsByTagName('body')[0].innerHtml;

    var configMatch = RegExp(r'var config = (\{[^}]*\})').firstMatch(html);
    if (configMatch == null) return '';

    // 获取匹配的config字符串
    var configString = configMatch.group(0)?.replaceFirst('var config = ', '');
    if (configString == null) return '';
    // 去除每行左右两边的空格，拼接成一行
    configString = configString.split('\n').map((e) => e.trim()).join();
    // 移除json中最后一个key-value尾部的逗号
    if (configString.endsWith(",}")) {
      configString = '${configString.substring(0, configString.length - 2)}}';
    }

    configString = '$configString}';
    configString = configString.replaceAll('\'', '"');
    // 将config字符串解析为Map
    var configMap = jsonDecode(configString);
    var result = await DioUtil.post(
        '${baseUrl.replaceFirst('www', 'player')}/api_config.php',
        data: {
          'url': configMap['url'],
          'time': configMap['time'],
          'key': configMap['key'],
        });
    if (!result.isSuccess) return '';

    String playUrlWithVerify = result.data.data['url'];
    return playUrlWithVerify;
  }

  Future<int?> getPlayRoute(String animeUrl) async {
    final detailDocument = await dioGetAndParse(animeUrl, isMobile: isMobile);
    if (detailDocument == null) return null;

    final playlists =
        detailDocument.getElementsByClassName('anthology-list-play');
    if (playlists.isEmpty) return null;

    final playlist = playlists.first;
    final aElements = playlist.getElementsByTagName('a');
    if (aElements.isEmpty) return null;

    final aElement = aElements.first;
    final relativeUrl = aElement.attributes['href'];
    if (relativeUrl == null || relativeUrl.isEmpty) return null;

    try {
      final playRoute =
          RegExp(r'([0-9]*)\/[0-9]*.html').firstMatch(relativeUrl)?.group(1);
      if (playRoute == null) return null;
      return int.tryParse(playRoute);
    } catch (e) {
      return null;
    }
  }
}
