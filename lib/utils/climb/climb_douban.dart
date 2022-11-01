import 'package:dio/dio.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/dio_package.dart';
import 'package:flutter_test_future/utils/result.dart';
import 'package:html/parser.dart';
import 'package:oktoast/oktoast.dart';

class ClimbDouban implements Climb {
  @override
  String baseUrl = "https://www.douban.com";

  @override
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    if (showMessage) showToast("该搜索源不支持更新");
    return anime;
  }

  @override
  Future<List<Anime>> climbAnimesByKeyword(String keyword,
      {bool showMessage = true}) async {
    List<Anime> animes = [];

    keyword = keyword.replaceAll(" ", "+"); // 网页搜索时输入空格会被替换为加号
    String url = "$baseUrl/search?q=$keyword";
    Result result = await DioPackage.get(url);

    if (result.code != 200) {
      if (showMessage) showToast(result.msg);
      return animes;
    }

    Response response = result.data;
    var document = parse(response.data);
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
      // debugPrint("element=${element.innerHtml}");
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
  Future<List<Anime>> climbDirectory(AnimeFilter filter) {
    // TODO: implement climbDirectory
    throw UnimplementedError();
  }
}
