import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/week_record.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/climb_yhdm.dart';

class ClimbQuqi with Climb {
  // 单例
  static final ClimbQuqi _instance = ClimbQuqi._();
  factory ClimbQuqi() => _instance;
  ClimbQuqi._();

  @override
  String get idName => "quqi";

  @override
  String get defaultBaseUrl => "https://www.quqim.net";

  @override
  String get sourceName => "曲奇动漫";

  @override
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    return ClimbYhdm().climbAnimeInfo(anime,
        foreignSourceName: sourceName, showMessage: showMessage);
  }

  @override
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) {
    return ClimbYhdm().climbDirectory(filter, pageParams,
        foreignBaseUrl: baseUrl, foreignSourceName: sourceName);
  }

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) {
    return ClimbYhdm().searchAnimeByKeyword(keyword,
        foreignBaseUrl: baseUrl, foreignSourceName: sourceName);
  }

  @override
  Future<List<WeekRecord>> climbWeeklyTable(int weekday) async {
    return ClimbYhdm().climbWeeklyTable(weekday,
        foreignBaseUrl: baseUrl, foreignSourceName: sourceName);
  }
}
