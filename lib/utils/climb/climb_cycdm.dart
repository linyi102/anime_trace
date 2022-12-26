import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:html/parser.dart';
import 'package:oktoast/oktoast.dart';

import '../../models/params/page_params.dart';
import '../dio_package.dart';
import '../result.dart';

// 次元城动漫
class ClimbCycdm implements Climb {
  @override
  // String baseUrl = "https://www.cycacg.com";
  String baseUrl = "https://www.cycdm01.top"; // 2022.10.27

  @override
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    debugPrint("爬取动漫详细网址：${anime.animeUrl}");
    Result result = await DioPackage.get(anime.animeUrl);
    if (result.code != 200) {
      if (showMessage) showToast(result.msg);
      return anime;
    }
    Response response = result.data;

    var document = parse(response.data);
    debugPrint("获取文档成功√，正在解析...");

    // 剧场版只有1集，但不会写上，所以没有badge
    var badge = document.getElementsByClassName("badge");
    if (badge.isNotEmpty) {
      anime.animeEpisodeCnt = int.parse(badge[0].innerHtml);
    }

    anime.animeCoverUrl = document
            .getElementsByClassName("detail-pic lazy mask-0")[0]
            .attributes["data-original"] ??
        anime.animeCoverUrl;
    anime.premiereTime = document
        .getElementsByClassName("slide-info-remarks")[1]
        .children[0]
        .innerHtml;
    anime.area = document
        .getElementsByClassName("slide-info-remarks")[2]
        .children[0]
        .innerHtml;
    anime.animeDesc = document
        .getElementsByClassName("check text selected cor3")[0]
        .innerHtml;

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

    debugPrint("解析完毕√");
    debugPrint(anime.toString());
    if (showMessage) showToast("更新信息成功");

    return anime;
  }

  @override
  Future<List<Anime>> climbAnimesByKeyword(String keyword) async {
    String url = baseUrl + "/search.html?wd=$keyword";
    List<Anime> climbAnimes = [];

    debugPrint("正在获取文档...");
    Result result = await DioPackage.get(url);
    if (result.code != 200) {
      showToast(result.msg);
      return [];
    }
    Response response = result.data;
    var document = parse(response.data);
    debugPrint("获取文档成功√，正在解析...");

    var coverElements = document.getElementsByClassName("lazy");

    for (var element in coverElements) {
      String? coverUrl = element.attributes["data-original"];
      if (coverUrl != null) {
        if (coverUrl.startsWith("//")) coverUrl = "https:$coverUrl";
        climbAnimes.add(
            Anime(animeName: "", animeEpisodeCnt: 0, animeCoverUrl: coverUrl));
        debugPrint("爬取封面：$coverUrl");
      }
    }

    var nameElements = document.getElementsByClassName("thumb-txt cor4 hide");
    var statusElements =
        document.getElementsByClassName("public-list-prb hide ft2");
    var urlElements = document.getElementsByClassName("public-list-exp");

    for (int i = 0; i < nameElements.length; ++i) {
      climbAnimes[i].animeName = nameElements[i].innerHtml;
      climbAnimes[i].playStatus = statusElements[i].innerHtml;
      // 获取网址
      String? animeUrl = urlElements[i].attributes["href"];
      climbAnimes[i].animeUrl = animeUrl == null ? "" : baseUrl + animeUrl;
      debugPrint("爬取动漫网址：${climbAnimes[i].animeUrl}");
    }

    debugPrint("解析完毕√");
    return climbAnimes;
  }

  @override
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) async {
    return [];
  }
}
