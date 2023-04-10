import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/utils/log.dart';

class ClimbOmofun extends Climb {
  // 单例
  static final ClimbOmofun _instance = ClimbOmofun._();
  factory ClimbOmofun() => _instance;
  ClimbOmofun._();

  @override
  String get baseUrl => "https://omofun.tv";

  @override
  String get sourceName => "OmoFun";

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword,
      {String url = "",
      String foreignBaseUrl = "",
      String? foreignSourceName}) async {
    if (url.isEmpty) {
      // 如果没有传入url，则说明访问的是omofun。如果url非空，则说明是同类型网站，直接使用传入的url
      url = baseUrl + "/vod/search.html?wd=$keyword";
    }
    List<Anime> climbAnimes = [];

    var document =
        await dioGetAndParse(url, foreignSourceName: foreignSourceName);
    if (document == null) {
      return [];
    }

    var elements = document.getElementsByClassName("lazy lazyload");

    for (var element in elements) {
      String? coverUrl = element.attributes["data-original"];
      String? animeName = element.attributes["alt"];
      if (coverUrl != null) {
        if (coverUrl.startsWith("//")) coverUrl = "https:$coverUrl";
        climbAnimes.add(Anime(
            animeName: animeName ?? "", // 没有名字时返回空串
            animeEpisodeCnt: 0,
            animeCoverUrl: coverUrl));
        Log.info("爬取封面：$coverUrl");
      }
    }

    var elementsInfo = document.getElementsByClassName("module-card-item-info");
    for (int i = 0; i < elementsInfo.length; ++i) {
      // 获取网址
      String? animeUrl =
          elementsInfo[i].getElementsByTagName("a")[0].attributes["href"];
      climbAnimes[i].animeUrl = animeUrl == null
          ? ""
          : ((foreignBaseUrl.isEmpty ? baseUrl : foreignBaseUrl) + animeUrl);
      Log.info("爬取动漫网址：${climbAnimes[i].animeUrl}");

      // 获取年份和地区
      // 2018<span class="slash">/</span>日本<span class="slash">/</span>
      List<String> strs = elementsInfo[i]
          .getElementsByClassName("module-info-item-content")[0]
          .innerHtml
          .split("<span class=\"slash\">/</span>");
      climbAnimes[i].premiereTime = strs[0];
      climbAnimes[i].area = strs[1];
    }

    // 获取播放状态
    elementsInfo = document.getElementsByClassName("module-item-note");
    for (int i = 0; i < elementsInfo.length; ++i) {
      climbAnimes[i].playStatus = elementsInfo[i].innerHtml;
    }

    // 获取动漫类型
    elementsInfo = document.getElementsByClassName("module-card-item-class");
    for (int i = 0; i < elementsInfo.length; ++i) {
      climbAnimes[i].category = elementsInfo[i].innerHtml;
    }

    Log.info("解析完毕√");
    return climbAnimes;
  }

  @override
  Future<Anime> climbAnimeInfo(Anime anime,
      {bool showMessage = true, String? foreignSourceName}) async {
    Log.info("爬取动漫详细网址：${anime.animeUrl}");
    var document = await dioGetAndParse(anime.animeUrl,
        foreignSourceName: foreignSourceName);
    if (document == null) {
      return anime;
    }

    List elements;
    if ((elements = document.getElementsByTagName("small")).length >= 2) {
      anime.animeEpisodeCnt =
          int.parse(elements[1].innerHtml); // 0对应今日更新，1对应该动漫的集数
    }
    // 播放状态在最后一个
    var moduleInfoItemContents =
        document.getElementsByClassName("module-info-item-content");
    anime.playStatus = moduleInfoItemContents.last.innerHtml;

    anime.premiereTime = document
        .getElementsByClassName("module-info-tag-link")[0]
        .getElementsByTagName("a")[0]
        .innerHtml;
    anime.area = document
        .getElementsByClassName("module-info-tag-link")[1]
        .getElementsByTagName("a")[0]
        .innerHtml;
    anime.animeCoverUrl = document
            .getElementsByClassName("module module-info")[0]
            .getElementsByTagName("img")[0]
            .attributes["data-original"] ??
        anime.animeCoverUrl;
    anime.animeDesc = document
        .getElementsByClassName("show-desc")[0]
        .getElementsByTagName("p")[0]
        .innerHtml;

    Log.info("解析完毕√");
    Log.info(anime.toString());
    if (showMessage) ToastUtil.showText("更新完毕");

    return anime;
  }

  @override
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) async {
    return [];
  }
}
