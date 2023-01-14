import 'package:dio/dio.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/dio_package.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/models/params/result.dart';
import 'package:html/parser.dart';
import 'package:oktoast/oktoast.dart';

import '../../models/params/page_params.dart';

class ClimbDouban implements Climb {
  @override
  String baseUrl = "https://www.douban.com";

  @override
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    Result result = await DioPackage.get(anime.animeUrl);
    if (result.code != 200) {
      if (showMessage) showToast(result.msg);
      return anime;
    }

    Response response = result.data;
    var document = parse(response.data);
    var mainpicElement = document.getElementById("mainpic");
    anime.animeCoverUrl = mainpicElement?.getElementsByTagName("img")[0].attributes["src"] ?? "";

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
        Log.info("又名=${line.substring(start, end)}");
        // anime.nameAnother = line.substring(start, end);
      } else if (line.contains("制片国家/地区")) {
        // Log.info("地区=${line.substring(start, end)}");
        anime.area = line.substring(start, end);
      }
    });

    if (infoElement != null) {
      var plElements = infoElement.getElementsByClassName("pl");
      for (var plElement in plElements) {
        String innerHtml = plElement.innerHtml;
        if (innerHtml.contains("首播")) {
          anime.premiereTime = plElement.nextElementSibling?.innerHtml ?? "";
        } else if (innerHtml.contains("作者")) {
          anime.authorOri = plElement.nextElementSibling?.innerHtml ?? "";
        }
      }
    }
    if (showMessage) showToast("更新信息成功");

    return anime;
  }

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword,
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
      // Log.info("element=${element.innerHtml}");
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
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) {
    throw UnimplementedError();
  }
}
