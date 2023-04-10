import 'package:dio/dio.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/models/params/result.dart';
import 'package:flutter_test_future/models/week_record.dart';
import 'package:flutter_test_future/utils/climb/site_collection_tab.dart';
import 'package:flutter_test_future/utils/climb/user_collection.dart';
import 'package:flutter_test_future/utils/dio_package.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

class Climb {
  /// 直接使用Climb.baseUrl，不用在意具体子类
  String baseUrl = "";

  String sourceName = "";

  /// 根据关键字搜索相关动漫(只需获取名字、封面链接、详细网址，之后会通过详细网址来获取其他信息)
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    throw '未实现';
  }

  /// 爬取动漫详细信息
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    throw '未实现';
  }

  /// 爬取目录
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) async {
    throw '未实现';
  }

  /// 爬取周表，weekday范围[1,7]
  Future<List<WeekRecord>> climbWeeklyTable(int weekday) async {
    throw '未实现';
  }

  //////////////////// 用户收藏 ////////////////////
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

  //////////////////// 统一解析 ////////////////////
  Future<Document?> dioGetAndParse(String url,
      {bool isMobile = false, String? foreignSourceName}) async {
    String sourceName = foreignSourceName ?? this.sourceName;

    Log.info("$sourceName：正在获取文档...");
    Result result = await DioPackage.get(url, isMobile: isMobile);
    if (result.code != 200) {
      ToastUtil.showText("$sourceName：${result.msg}");
      return null;
    }
    Response response = result.data;
    Log.info("$sourceName：获取文档成功√");
    Document document = parse(response.data);
    return document;
  }
}
