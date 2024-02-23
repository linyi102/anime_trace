import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/site_collection_tab.dart';
import 'package:flutter_test_future/utils/climb/user_collection.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:html/dom.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

class ClimbBangumi with Climb {
  // 单例
  static final ClimbBangumi _instance = ClimbBangumi._();
  factory ClimbBangumi() => _instance;
  ClimbBangumi._();

  @override
  String get idName => "bangumi";

  @override
  String get defaultBaseUrl => "https://bangumi.tv";

  @override
  String get sourceName => "Bangumi";

  @override
  List<SiteCollectionTab> get siteCollectionTabs => [
        SiteCollectionTab(title: "想看", word: "wish"),
        SiteCollectionTab(title: "看过", word: "collect"),
        SiteCollectionTab(title: "在看", word: "do"),
        SiteCollectionTab(title: "搁置", word: "on_hold"),
        SiteCollectionTab(title: "放弃", word: "dropped"),
      ];

  @override
  String get userCollBaseUrl => "$baseUrl/anime/list";

  @override
  int get userCollPageSize => 24;

  /// 根据关键字搜索相关动漫(只需获取名字、封面链接、详细网址，之后会通过详细网址来获取其他信息)
  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    String url = baseUrl +
        "/subject_search/$keyword?cat=${SPKey.getSelectedBangumiSearchCategoryKey()}";
    List<Anime> climbAnimes = [];

    var document = await dioGetAndParse(url);
    if (document == null) {
      return [];
    }

    climbAnimes = parseAnimeListByBrowserItemList(document);
    return climbAnimes;
  }

  /// 爬取动漫详细信息
  @override
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    Log.info("爬取动漫详细网址：${anime.animeUrl}");
    var document = await dioGetAndParse(anime.animeUrl);
    if (document == null) {
      return anime;
    }

    String? img = document
        .getElementById("bangumiInfo")
        ?.getElementsByTagName("a")[0]
        .attributes["href"];
    if (img != null) {
      if (!img.startsWith("https:")) img = "https:$img";
      anime.animeCoverUrl = img;
    }

    String? desc = document.getElementById("subject_summary")?.innerHtml;
    if (desc != null) {
      anime.animeDesc = desc.replaceAll("<br>", "");
    }

    final infobox = document.getElementById("infobox");
    if (infobox != null) {
      final lis = infobox.getElementsByTagName("li");
      if (lis.length > 1 && lis[1].innerHtml.contains("话数")) {
        String tmpStr = lis[1].innerHtml;
        tmpStr = tmpStr.replaceAll('<span class="tip">话数: </span>', '');
        anime.animeEpisodeCnt = int.tryParse(tmpStr) ?? anime.animeEpisodeCnt;
      }
    }

    Log.info("解析完毕√");
    Log.info(anime.toString());
    if (showMessage) ToastUtil.showText("更新完毕");

    return anime;
  }

  /// 查询是否存在该用户
  @override
  Future<bool> existUser(String userId) async {
    String url = "$userCollBaseUrl/$userId";

    var document = await dioGetAndParse(url);
    if (document == null) return false;

    // <div class="message">
    // <h2>呜咕，出错了</h2>
    // <p class="text">数据库中没有查询到该用户的信息</p>
    if (document.getElementsByClassName("message").isNotEmpty) return false;

    return true;
  }

  /// 查询用户某个收藏下的列表
  @override
  Future<UserCollection> climbUserCollection(
      String userId, SiteCollectionTab siteCollectionTab,
      {int page = 1}) async {
    String url =
        "$userCollBaseUrl/$userId/${siteCollectionTab.word}?page=$page";

    UserCollection userCollection = UserCollection(totalCnt: 0, animes: []);
    var document = await dioGetAndParse(url);
    if (document == null) {
      return userCollection;
    }

    // 获取该tab动漫数量
    // <li><a href="/anime/list/509755/wish" ><span>想看        (44)</span></a></li>                        <li><a href="/anime/list/509755/collect" class="focus"><span>看过        (138)</span></a></li>                        <li><a href="/anime/list/509755/do" ><span>在看        (56)</span></a></li>                        <li><a href="/anime/list/509755/on_hold" ><span>搁置        (6)</span></a></li>                        <li><a href="/anime/list/509755/dropped" ><span>抛弃        (1)</span></a></li>        </ul>
    // 懒惰匹配 wish.*?\([0-9]*\)
    // 可以匹配到 wish" ><span>想看        (44)
    var navSubTabs = document.getElementsByClassName("navSubTabs")[0];
    var str = RegExp("${siteCollectionTab.word}.*?\\([0-9]*\\)")
        .firstMatch(navSubTabs.innerHtml)?[0];
    if (str != null) {
      str = str.substring(str.indexOf("(") + 1, str.indexOf(")"));
      userCollection.totalCnt = int.tryParse(str) ?? 0;
    }

    // 在原来基础上添加(加载更多)，所以使用addAll，而非赋值
    userCollection.animes.addAll(parseAnimeListByBrowserItemList(document));
    return userCollection;
  }

  List<Anime> parseAnimeListByBrowserItemList(Document document) {
    var lis =
        document.getElementById("browserItemList")?.getElementsByTagName("li");
    if (lis == null || lis.isEmpty) {
      return [];
    }

    List<Anime> animes = [];
    // 获取该页动漫列表
    for (var li in lis) {
      String detailUrl =
          li.getElementsByTagName("a")[0].attributes["href"] ?? "";
      String animeUrl = "$baseUrl$detailUrl";

      var imgElements = li.getElementsByTagName("img");
      String img = "";
      // 有些没有封面，例如魔法科高校的劣等生 续篇
      if (imgElements.isNotEmpty) img = imgElements[0].attributes["src"] ?? "";
      if (!img.startsWith("https:")) img = "https:$img";

      var inner = li.getElementsByClassName("inner")[0];
      String name = inner.getElementsByTagName("a")[0].innerHtml;
      var smallEs = inner.getElementsByTagName("small");
      String nameAnother = "";
      if (smallEs.isNotEmpty) nameAnother = smallEs.first.innerHtml;

      String tempInfo =
          inner.getElementsByClassName("info tip")[0].innerHtml.trim();

      // 解析集数和日期
      // 示例
      // 2023年1月7日 / 益山亮司 / 「NieR:Automata」 (スクウェア・エニックス) / 中井準
      // 12话 / 2023年1月6日 / 吉村文宏 / 恵ノ島すず(カドカワBOOKS)[原作]、逆木ルミヲ(B's-LOG COMICS)[漫画] / 片山みゆき
      // こげたおこげ / コアミックス
      // 2020-07-17 / 横槍メンゴ / 集英社
      // 2023年 / 大庭秀昭 / いのり。(愛中出版・一迅社刊) / 佐藤陽子
      var infos =
          inner.getElementsByClassName("info tip")[0].innerHtml.split("/");
      int episodeCnt = 0;
      var tmpTimeStr = "";
      if (infos.isNotEmpty) {
        var episodeCntStr = infos[0].trim();
        if (infos[0].contains("话")) {
          episodeCntStr = episodeCntStr.substring(0, episodeCntStr.length - 1);
          episodeCnt = int.tryParse(episodeCntStr) ?? 0;

          // 如果infos[0]是集数，那么infos[1]就是日期
          if (infos.length >= 2) {
            tmpTimeStr = infos[1].trim();
            if (tmpTimeStr.contains("年")) {
              tmpTimeStr = tmpTimeStr;
            }
          }
        } else {
          // 如果infos[0]没有集数，那么就是首播时间
          tmpTimeStr = infos[0].trim();
        }
      }

      String timeStr = "";
      if (tmpTimeStr.contains("年")) {
        String year = tmpTimeStr.substring(0, tmpTimeStr.indexOf("年"));
        timeStr += year;
        // 提取年月日，月日填充前置0
        if (tmpTimeStr.contains("月")) {
          String month = tmpTimeStr.substring(
              tmpTimeStr.indexOf("年") + 1, tmpTimeStr.indexOf("月"));
          if (month.length == 1) month = "0$month";
          timeStr += "-$month";

          if (tmpTimeStr.contains("日")) {
            String day = tmpTimeStr.substring(
                tmpTimeStr.indexOf("月") + 1, tmpTimeStr.indexOf("日"));
            if (day.length == 1) day = "0$day";
            timeStr += "-$day";
          }
        }
      } else {
        timeStr =
            RegExp("[0-9]{4}-[0-9]{2}-[0-9]{2}").firstMatch(tmpTimeStr)?[0] ??
                "";
      }

      Anime anime = Anime(
        animeName: name,
        nameAnother: nameAnother,
        animeCoverUrl: img,
        animeUrl: animeUrl,
        animeEpisodeCnt: episodeCnt,
        premiereTime: timeStr,
        tempInfo: tempInfo,
      );
      animes.add(anime);
    }

    return animes;
  }
}
