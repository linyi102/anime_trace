import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/filter.dart';

abstract class Climb {
  late String baseUrl;

  Future<Anime> climbAnimeInfo(Anime anime);
  Future<List<Anime>> climbAnimesByKeyword(String keyword);
  Future<List<Anime>> climbDirectory(Filter filter);
}
