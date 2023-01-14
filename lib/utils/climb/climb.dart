import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';

import '../../models/params/page_params.dart';

abstract class Climb {
  late String baseUrl;
  // 根据关键字搜索相关动漫(只需获取名字、封面链接、详细网址，之后会通过详细网址来获取其他信息)
  Future<List<Anime>> searchAnimeByKeyword(String keyword);
  // 爬取动漫详细信息
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true});
  // 爬取目录
  Future<List<Anime>> climbDirectory(AnimeFilter filter, PageParams pageParams);
}
