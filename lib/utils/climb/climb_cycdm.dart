import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

// 次元城动漫
class ClimbCycdm extends Climb {
  // 单例
  static final ClimbCycdm _instance = ClimbCycdm._();
  factory ClimbCycdm() => _instance;
  ClimbCycdm._();

  @override
  // String baseUrl = "https://www.cycacg.com";
  String get baseUrl => "https://www.cycdm01.top"; // 2022.10.27
  @override
  String get sourceName => "次元城动漫";

  bool isMobile = true;

  @override
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    Log.info("爬取动漫详细网址：${anime.animeUrl}");
    var document = await dioGetAndParse(anime.animeUrl, isMobile: isMobile);
    if (document == null) {
      return anime;
    }

    anime.animeEpisodeCnt = document
        .getElementsByClassName("anthology-list-box")[0]
        .getElementsByTagName("li")
        .length;

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

    Log.info("解析完毕√");
    Log.info(anime.toString());
    if (showMessage) ToastUtil.showText("更新完毕");

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
      String? coverUrl = element.attributes["data-original"];
      if (coverUrl != null) {
        if (coverUrl.startsWith("//")) coverUrl = "https:$coverUrl";
        climbAnimes.add(
            Anime(animeName: "", animeEpisodeCnt: 0, animeCoverUrl: coverUrl));
        Log.info("爬取封面：$coverUrl");
      }
    }

    var nameElements = document.getElementsByClassName("thumb-txt cor4 hide");
    var urlElements = document.getElementsByClassName("public-list-exp");

    for (int i = 0; i < nameElements.length; ++i) {
      climbAnimes[i].animeName = nameElements[i].innerHtml;
      // 获取网址
      String? animeUrl = urlElements[i].attributes["href"];
      climbAnimes[i].animeUrl = animeUrl == null ? "" : baseUrl + animeUrl;
      Log.info("爬取动漫网址：${climbAnimes[i].animeUrl}");
    }

    Log.info("解析完毕√");
    return climbAnimes;
  }

  @override
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) async {
    return [];
  }
}
