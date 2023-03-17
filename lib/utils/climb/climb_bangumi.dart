import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
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
  List<UserCollection> get collections => [
        UserCollection(title: "想看", word: "wish"),
        UserCollection(title: "看过", word: "collect"),
        UserCollection(title: "在看", word: "do"),
        UserCollection(title: "搁置", word: "on_hold"),
        UserCollection(title: "放弃", word: "dropped"),
      ];

  @override
  String get userCollBaseUrl => "$baseUrl/anime/list/";

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
    throw '未实现';
  }

  /// 查询用户某个收藏下的总数
  @override
  Future<int> climbUserCollectionCnt(
    String userId,
    UserCollection userCollection,
  ) async {
    throw '未实现';
  }

  /// 查询用户某个收藏下的列表
  @override
  Future<List<Anime>> climbUserCollection(
      String userId, UserCollection userCollection,
      {int page = 1}) async {
    throw '未实现';
  }
}
