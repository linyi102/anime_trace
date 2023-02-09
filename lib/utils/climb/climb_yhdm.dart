import 'package:dio/dio.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/dio_package.dart';
import 'package:flutter_test_future/models/params/result.dart';
import 'package:html/parser.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_test_future/utils/log.dart';

class ClimbYhdm extends Climb {
  // 单例，作用是曲奇动漫使用ClimbYhdm().方法时，不会再次创建ClimbYhdm对象
  static final ClimbYhdm _instance = ClimbYhdm._();
  factory ClimbYhdm() => _instance;
  ClimbYhdm._();

  @override
  String baseUrl = "https://www.yhdmp.cc";

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword,
      {String? foreignBaseUrl, String sourceName = "樱花动漫"}) async {
    String url = "${foreignBaseUrl ?? baseUrl}/s_all?ex=1&kw=$keyword";
    return _climbOfyhdm(foreignBaseUrl ?? baseUrl, url, sourceName: sourceName);
  }

  @override
  Future<Anime> climbAnimeInfo(Anime anime,
      {bool showMessage = true, String sourceName = "樱花动漫"}) async {
    Result result = await DioPackage.get(anime.animeUrl);
    if (result.code != 200) {
      if (showMessage) showToast("$sourceName：${result.msg}");
      return anime;
    }
    Response response = result.data;
    var document = parse(response.data);
    var animeInfo = document.getElementsByClassName("sinfo")[0];
    String str = animeInfo.getElementsByTagName("p")[0].innerHtml;
    // str内容：
    // <label>别名:</label>古見さんは、コミ ュ症です。2期
    // Log.info("str=$str");
    anime.nameAnother = str.substring(str.lastIndexOf(">") + 1); // +1跳过找的>
    // 获取封面
    String? coverUrl = document
        .getElementsByClassName("thumb")[0]
        .getElementsByTagName("img")[0]
        .attributes["src"];
    if (coverUrl != null && coverUrl.startsWith("//")) {
      anime.animeCoverUrl = "https:$coverUrl";
    }
    // 获取首播时间
    // <a href="/list/?year=2020" target="_blank">2020</a>-01-11
    // <a href="/list/?year=2022" target="_blank">2022</a>-10
    // <a href="/list/?year=2022" target="_blank">2022</a>
    var element = animeInfo.getElementsByTagName("span")[0];
    str = element.innerHtml.trimRight(); // 需要去除右边的空白符
    String destStr = "target=\"_blank\">";
    // 从字符串中找到target="_blank">并跳过该子串，取后面所有子串
    anime.premiereTime =
        str.substring(str.lastIndexOf(destStr) + destStr.length);
    // 然后删除其中的</a>
    anime.premiereTime = anime.premiereTime.replaceAll("</a>", "");

    // 获取其他信息
    anime.area = animeInfo
        .getElementsByTagName("span")[1]
        .getElementsByTagName("a")[0]
        .innerHtml;
    anime.category = animeInfo
        .getElementsByTagName("span")[4]
        .getElementsByTagName("a")[0]
        .innerHtml;
    anime.playStatus = animeInfo
        .getElementsByTagName("span")[4]
        .getElementsByTagName("a")[2]
        .innerHtml;
    anime.animeDesc = document.getElementsByClassName("info")[0].innerHtml;
    // 获取集数
    String episodeCntStr = animeInfo.getElementsByTagName("p")[1].innerHtml;
    Log.info("开始解析集数：${anime.animeName}");
    anime.animeEpisodeCnt = parseEpisodeCntOfyhdm(episodeCntStr);
    if (showMessage) showToast("更新完毕");

    Log.info(anime.toString());
    return anime;
  }

  // 解析樱花动漫里的集数
  static int parseEpisodeCntOfyhdm(String episodeCntStr) {
    int episodeCnt = 0;
    if (episodeCntStr.contains("[全集]")) {
      episodeCnt = 1;
    } else if (episodeCntStr.contains("第")) {
      // 例如：第13集(完结)，第59话
      // 特例：擅长捉弄的高木同学OVA的「第OVA1话」
      int episodeCntStartIndex = episodeCntStr.indexOf("第") + 1;
      int episodeCntEndIndex = episodeCntStr.indexOf("集");
      if (episodeCntEndIndex == -1) {
        episodeCntEndIndex = episodeCntStr.indexOf("话");
      }
      if (episodeCntStartIndex < episodeCntEndIndex) {
        try {
          episodeCnt = int.parse(episodeCntStr.substring(
              episodeCntStartIndex, episodeCntEndIndex));
        } catch (e) {
          Log.info("解析出错：$episodeCntStr");
        }
      }
    } else if (episodeCntStr.contains("01-")) {
      // 例如：[TV 01-12+OVA+SP]
      int episodeCntStartIndex = episodeCntStr.indexOf("01-") + 3; // 跳过01-
      // [start, end)，中间有2个数字，即集数
      episodeCnt = int.parse(episodeCntStr.substring(
          episodeCntStartIndex, episodeCntStartIndex + 2));
    }
    return episodeCnt;
  }

  // 目录页和搜索页的结果一致，只是链接不一样，共用爬取片段
  static Future<List<Anime>> _climbOfyhdm(String baseUrl, String url,
      {String sourceName = "樱花动漫"}) async {
    List<Anime> animes = [];
    Result result = await DioPackage.get(url);
    if (result.code != 200) {
      showToast("$sourceName：${result.msg}");
      return [];
    }
    Response response = result.data;
    var document = parse(response.data);
    var lpic = document.getElementsByClassName("lpic")[0];
    var lis = lpic.getElementsByTagName("li");
    for (var li in lis) {
      String desc = li.getElementsByTagName("p")[0].innerHtml;
      String episodeCntStr = li.getElementsByTagName("font")[0].innerHtml;
      int episodeCnt = parseEpisodeCntOfyhdm(episodeCntStr);

      String? coverUrl = li.getElementsByTagName("img")[0].attributes["src"];
      if (coverUrl != null && coverUrl.startsWith("//")) {
        coverUrl = "https:$coverUrl";
      }
      String? animeName = li.getElementsByTagName("img")[0].attributes["alt"];
      String animeUrl =
          baseUrl + (li.getElementsByTagName("a")[0].attributes["href"] ?? "");
      Anime anime = Anime(
        animeName: animeName ?? "", // 没有名字时返回空串
        animeEpisodeCnt: episodeCnt,
        animeDesc: desc,
        animeCoverUrl: coverUrl ?? "",
        animeUrl: animeUrl,
      );
      Log.info("爬取名字：${anime.animeName}");
      Log.info("爬取封面：${anime.animeCoverUrl}");
      animes.add(anime);
    }
    return animes;
  }

  @override
  Future<List<Anime>> climbDirectory(AnimeFilter filter, PageParams pageParams,
      {String? foreignBaseUrl, String sourceName = "樱花动漫"}) async {
    String url =
        "${foreignBaseUrl ?? baseUrl}/list/?region=${filter.region}&year=${filter.year}&season=${filter.season}&status=${filter.status}&label=${filter.label}&order=${filter.order}&genre=${filter.category}";
    url = "$url&pageindex=${pageParams.pageIndex}";

    List<Anime> directory = await _climbOfyhdm(foreignBaseUrl ?? baseUrl, url,
        sourceName: sourceName);
    return directory;
  }
}
