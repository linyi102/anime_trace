// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:html/parser.dart';

class ClimeCoverUtil {
  // 刷新动漫封面
  static Future<String> climeCoverUrl(String keyword) async {
    String coverUrl = "";
    coverUrl = await sourceOfyhdm(keyword);

    return coverUrl;
  }

  static Future<String> sourceOfyhdm(String keyword) async {
    String url = "https://www.yhdmp.cc/s_all?ex=1&kw=$keyword";
    try {
      var response = await Dio().get(url);
      var document = parse(response.data);
      var elements = document.getElementsByClassName("lpic");
      String? coverUrl = elements[0]
          .children[0]
          .children[
              0] // 可能并没有元素，因此会提示：RangeError (index): Invalid value: Valid value range is empty: 0
          .children[0]
          .children[0]
          .attributes["src"];
      if (coverUrl != null && coverUrl.startsWith("//")) {
        coverUrl = "https:$coverUrl";
      }
      return coverUrl ?? ""; // 搜不到则返回空串
    } catch (e) {
      print(e);
      return "";
    }
  }

  // 添加动漫
  static Future<List<Anime>> climeAllCoverUrl(String keyword) async {
    List<Anime> allAnimeNameAndCoverUrl = [];

    String selectedWebsite =
        SPUtil.getString("selectedWebsite", defaultValue: "樱花动漫");
    if (selectedWebsite == "樱花动漫") {
      allAnimeNameAndCoverUrl = await climeAllSourceOfyhdm(keyword);
    } else if (selectedWebsite == "OmoFun") {
      allAnimeNameAndCoverUrl = await climeAllSourceOfOmoFun(keyword);
    } else {
      throw ("爬取的网站名错误: $selectedWebsite");
    }
    return allAnimeNameAndCoverUrl;
  }

  static Future<List<Anime>> climeAllSourceOfyhdm(String keyword) async {
    String url = "https://www.yhdmp.cc/s_all?ex=1&kw=$keyword";
    List<Anime> allAnimeNameAndCoverUrl = [];
    try {
      var response = await Dio().get(url);
      var document = parse(response.data);
      var elements = document.getElementsByTagName("img");
      for (var element in elements) {
        String? coverUrl = element.attributes["src"];
        String? animeName = element.attributes["alt"];
        if (coverUrl != null) {
          if (coverUrl.startsWith("//")) coverUrl = "https:$coverUrl";
          allAnimeNameAndCoverUrl.add(Anime(
              animeName: animeName ?? "", // 没有名字时返回空串
              animeEpisodeCnt: 0,
              animeCoverUrl: coverUrl));
          print("爬取封面：$coverUrl");
        }
      }
    } catch (e) {
      print(e);
    }
    return allAnimeNameAndCoverUrl;
  }

  static Future<List<Anime>> climeAllSourceOfOmoFun(String keyword) async {
    String url = "https://omofun.tv/index.php/vod/search.html?wd=$keyword";
    List<Anime> allAnimeNameAndCoverUrl = [];
    try {
      var response = await Dio().get(url);
      var document = parse(response.data);
      var elements = document.getElementsByClassName("lazy lazyload");
      for (var element in elements) {
        String? coverUrl = element.attributes["data-src"];
        String? animeName = element.attributes["alt"];
        if (coverUrl != null) {
          if (coverUrl.startsWith("//")) coverUrl = "https:$coverUrl";
          allAnimeNameAndCoverUrl.add(Anime(
              animeName: animeName ?? "", // 没有名字时返回空串
              animeEpisodeCnt: 0,
              animeCoverUrl: coverUrl));
          print("爬取封面：$coverUrl");
        }
      }
    } catch (e) {
      print(e);
    }
    return allAnimeNameAndCoverUrl;
  }
}
