import 'package:flutter_test_future/models/anime.dart';

class WeekRecord {
  Anime anime;
  String info; // 因为有些记录没有集数，只显示「完结」，所以改用info而非episodeNumber

  WeekRecord({required this.anime, required this.info});
}
