import 'package:dio/dio.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:html/parser.dart';
import 'package:oktoast/oktoast.dart';

import '../dio_package.dart';
import '../log.dart';
import '../../models/params/result.dart';

class ClimbQdm implements Climb {
  @override
  String baseUrl = "https://www.qdm66.com";

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    String url = baseUrl + "/search/-------------.html?wd=$keyword";
    List<Anime> climbAnimes = [];

    Log.info("正在获取文档...");
    Result result = await DioPackage.get(url);
    if (result.code != 200) {
      showToast("趣动漫：${result.msg}");
      return [];
    }
    Response response = result.data;
    var document = parse(response.data);
    Log.info("获取文档成功√，正在解析...");

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
    Log.info("爬取动漫详细网址：${anime.animeUrl}");
    Result result = await DioPackage.get(anime.animeUrl);
    if (result.code != 200) {
      if (showMessage) showToast("趣动漫：${result.msg}");
      return anime;
    }
    Response response = result.data;

    var document = parse(response.data);
    Log.info("获取文档成功√，正在解析...");

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

    if (showMessage) showToast("更新完毕");

    return anime;
  }

  @override
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) {
    // TODO: implement climbDirectory
    throw UnimplementedError();
  }
}
