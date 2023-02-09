import 'package:dio/dio.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/params/result.dart';
import 'package:flutter_test_future/models/week_record.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/climb_yhdm.dart';
import 'package:flutter_test_future/utils/dio_package.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:html/parser.dart';
import 'package:oktoast/oktoast.dart';

class ClimbQuqi extends Climb {
  String baseUrl = "https://www.quqim.net";
  String sourceName = "曲奇动漫";

  @override
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    return ClimbYhdm().climbAnimeInfo(anime,
        sourceName: sourceName, showMessage: showMessage);
  }

  @override
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) {
    return ClimbYhdm().climbDirectory(filter, pageParams,
        foreignBaseUrl: baseUrl, sourceName: sourceName);
  }

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) {
    return ClimbYhdm().searchAnimeByKeyword(keyword,
        foreignBaseUrl: baseUrl, sourceName: sourceName);
  }

  @override
  Future<List<WeekRecord>> climbWeeklyTable(int weekday) async {
    if (weekday <= 0 || weekday > 7) {
      showToast("获取错误：weekday=$weekday");
      return [];
    }

    List<WeekRecord> records = [];
    String url = baseUrl;

    Log.info("正在获取文档...");
    Result result = await DioPackage.get(url);
    if (result.code != 200) {
      showToast("$sourceName：${result.msg}");
      return [];
    }
    Response response = result.data;
    var document = parse(response.data);
    Log.info("获取文档成功√，正在解析...");

    var tlist = document.getElementsByClassName("tlist")[0];
    var ul = tlist.getElementsByTagName("ul")[weekday - 1];
    var lis = ul.getElementsByTagName("li");

    RegExp regExp = RegExp("第[0-9]{1,}集");
    for (var li in lis) {
      var as = li.getElementsByTagName("a");

      Anime anime = Anime(animeName: "");
      anime.animeName = as[1].innerHtml;
      anime.animeUrl = "$baseUrl${as[1].attributes["href"]}";

      // 因为有些记录没有集数，只显示「完结」，所以改用info而非episodeNumber
      // innerHtml的三种情况：
      // 第16集(完结)
      // 第5集
      // 第16集<font color="#FF0000"> new</font>
      String info = regExp.stringMatch(as[0].innerHtml).toString();

      records.add(WeekRecord(anime: anime, info: info));
    }

    return records;
  }
}
