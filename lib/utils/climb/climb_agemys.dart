import 'package:dio/dio.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/climb_yhdm.dart';
import 'package:flutter_test_future/utils/dio_package.dart';
import 'package:flutter_test_future/utils/result.dart';
import 'package:html/parser.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../../models/params/page_params.dart';

class ClimbAgemys implements Climb {
  @override
  // String baseUrl = "https://www.agemys.cc";
  String baseUrl = "https://www.agemys.net"; // 2022.10.27

  @override
  Future<List<Anime>> climbAnimesByKeyword(String keyword,
      {bool showMessage = true}) async {
    String url = baseUrl + "/search?query=$keyword";
    List<Anime> climbAnimes = [];

    Log.info("正在获取文档...");
    Result result = await DioPackage.get(url);
    if (result.code != 200) {
      if (showMessage) showToast(result.msg);

      return [];
    }
    Response response = result.data;
    var document = parse(response.data);
    Log.info("获取文档成功√，正在解析...");

    var elements = document.getElementsByClassName("cell_poster");

    for (var element in elements) {
      String? coverUrl =
          element.getElementsByTagName("img")[0].attributes["src"];
      String? animeName =
          element.getElementsByTagName("img")[0].attributes["alt"];
      String? animeUrl = element.attributes["href"];
      String? episodeCntStr =
          element.getElementsByClassName("newname")[0].innerHtml;
      int episodeCnt = ClimbYhdm.parseEpisodeCntOfyhdm(
          episodeCntStr); // AGE动漫的集表示和樱花动漫的一致，因此也使用这个解析
      if (coverUrl != null) {
        if (coverUrl.startsWith("//")) coverUrl = "https:$coverUrl";
      }

      Anime climbAnime = Anime(
        animeName: animeName ?? "",
        animeEpisodeCnt: episodeCnt,
        animeCoverUrl: coverUrl ?? "",
        animeUrl: animeUrl == null ? "" : (baseUrl + animeUrl),
      );
      Log.info("爬取封面：$coverUrl");
      Log.info("爬取动漫网址：${climbAnime.animeUrl}");

      // 注意是document，而上面的element只是用于获取图片，以及得知查询的动漫数量
      climbAnime.category =
          document.getElementsByClassName("cell_imform_value")[0].innerHtml;
      climbAnime.nameOri =
          document.getElementsByClassName("cell_imform_value")[1].innerHtml;
      climbAnime.nameAnother =
          document.getElementsByClassName("cell_imform_value")[2].innerHtml;
      if (climbAnime.nameAnother == "暂无") climbAnime.nameAnother = "";
      climbAnime.premiereTime =
          document.getElementsByClassName("cell_imform_value")[3].innerHtml;
      climbAnime.playStatus =
          document.getElementsByClassName("cell_imform_value")[4].innerHtml;
      climbAnime.authorOri =
          document.getElementsByClassName("cell_imform_value")[5].innerHtml;
      // 6：剧情类型
      climbAnime.productionCompany =
          document.getElementsByClassName("cell_imform_value")[7].innerHtml;
      climbAnime.animeDesc =
          document.getElementsByClassName("cell_imform_desc")[0].innerHtml;

      climbAnimes.add(climbAnime);
    }
    Log.info("解析完毕√");
    return climbAnimes;
  }

  @override
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    // Log.info("正在获取文档...");
    // var response = await Dio().get(anime.animeUrl);
    // var document = parse(response.data);
    // Log.info("获取文档成功√，正在解析...");
    // 因为该动漫网址集数不容易解析，但又因为查询页面中很多信息都已经写上了，还包括了容易解析的集信息
    // 所以根据该动漫名查询，然后根据动漫地址找到动漫并更新信息
    List<Anime> climbAnimes =
        await climbAnimesByKeyword(anime.animeName, showMessage: showMessage);
    for (var climbAnime in climbAnimes) {
      if (climbAnime.animeUrl == anime.animeUrl) {
        // 不能直接赋值，因为有id等信息
        anime.animeEpisodeCnt = climbAnime.animeEpisodeCnt;
        anime.playStatus = climbAnime.playStatus;
        anime.animeCoverUrl = climbAnime.animeCoverUrl;
        break;
      }
    }
    Log.info("解析完毕√");
    Log.info(anime.toString());
    if (showMessage) showToast("更新信息成功");

    return anime;
  }

  @override
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) async {
    return [];
  }
}
