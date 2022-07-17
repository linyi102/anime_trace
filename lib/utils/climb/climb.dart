import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/filter.dart';

abstract class Climb {
  late String baseUrl;
  // 爬取动漫详细信息
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true});
  // 根据关键字搜索相关动漫
  Future<List<Anime>> climbAnimesByKeyword(String keyword);
  // 爬取目录
  Future<List<Anime>> climbDirectory(Filter filter);
}
