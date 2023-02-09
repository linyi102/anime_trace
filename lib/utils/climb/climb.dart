import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/models/week_record.dart';

class Climb {
  String baseUrl = "";

  // 根据关键字搜索相关动漫(只需获取名字、封面链接、详细网址，之后会通过详细网址来获取其他信息)
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    throw '未实现';
  }

  // 爬取动漫详细信息
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    throw '未实现';
  }

  // 爬取目录
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) async {
    throw '未实现';
  }

  // 爬取周表
  Future<List<WeekRecord>> climbWeeklyTable(int weekday) async {
    throw '未实现';
  }
}
