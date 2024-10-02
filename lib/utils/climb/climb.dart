import 'package:dio/dio.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/models/params/result.dart';
import 'package:flutter_test_future/models/week_record.dart';
import 'package:flutter_test_future/utils/climb/site_collection_tab.dart';
import 'package:flutter_test_future/utils/climb/user_collection.dart';
import 'package:flutter_test_future/utils/dio_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

mixin Climb {
  late String idName;

  late String customBaseUrlKey = "${idName}CustomBaseUrl";

  String get customBaseUrl =>
      SPUtil.getString(customBaseUrlKey, defaultValue: "");

  set customBaseUrl(String url) {
    if (!url.startsWith("https://") && !url.startsWith("http://")) {
      url = 'https://$url';
    }
    if (url.endsWith("/") && url.length > 1) {
      url = url.substring(0, url.length - 1);
    }
    SPUtil.setString(customBaseUrlKey, url);
  }

  Future<void> removeCustomBaseUrl() async {
    await SPUtil.remove(customBaseUrlKey);
  }

  String get baseUrl => customBaseUrl.isEmpty ? defaultBaseUrl : customBaseUrl;

  String defaultBaseUrl = "";

  String sourceName = "";

  /// 根据关键字搜索相关动漫(只需获取名字、封面链接、详细网址，之后会通过详细网址来获取其他信息)
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    throw '未实现';
  }

  /// 爬取动漫详细信息
  Future<Anime> climbAnimeInfo(Anime anime) async {
    throw '未实现';
  }

  /// 爬取目录
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) async {
    throw '未实现';
  }

  Future<List<List<WeekRecord>>> climbWeeklyTable() async {
    throw '未实现';
  }

  /// 用户收藏链接
  String userCollBaseUrl = "";

  List<SiteCollectionTab> siteCollectionTabs = [];

  int userCollPageSize = 0;

  /// 查询是否存在该用户
  Future<bool> existUser(String userId) async {
    throw '未实现';
  }

  /// 查询用户某个收藏下的列表
  Future<UserCollection> climbUserCollection(
      String userId, SiteCollectionTab siteCollectionTab,
      {int page = 1}) async {
    throw '未实现';
  }

  /// 获取视频链接
  Future<String> getVideoUrl(String animeUrl, int episodeNumber) async {
    throw '未实现';
  }

  /// 统一解析
  Future<Document?> dioGetAndParse(String url,
      {bool isMobile = false, String? foreignSourceName}) async {
    String sourceName = foreignSourceName ?? this.sourceName;

    Result result = await DioUtil.get(url, isMobile: isMobile);
    if (result.code != 200) {
      ToastUtil.showText("$sourceName：${result.msg}");
      return null;
    }
    Response response = result.data;
    Document document = parse(response.data);
    return document;
  }
}
