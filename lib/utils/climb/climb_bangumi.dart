import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/site_collection_tab.dart';
import 'package:flutter_test_future/utils/climb/user_collection.dart';

class ClimbBangumi extends Climb {
  // 单例
  static final ClimbBangumi _instance = ClimbBangumi._();
  factory ClimbBangumi() => _instance;
  ClimbBangumi._();

  @override
  String get baseUrl => "https://bangumi.tv";

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
    throw '未实现';
  }

  /// 爬取动漫详细信息
  @override
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    throw '未实现';
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

    var lis =
        document.getElementById("browserItemList")?.getElementsByTagName("li");
    if (lis == null || lis.isEmpty) {
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
      userCollection.animes.add(anime);
    }

    return userCollection;
  }
}
