// ignore_for_file: avoid_print

import 'package:flutter_test_future/utils/anime.dart';

main(List<String> args) {
  Anime animeInfo = Anime("anime_name", tag: "todo");
  animeInfo.setEndEpisode(12);
  print(animeInfo);
  animeInfo.setEpisodeDateTimeNow(1);
  animeInfo.setEpisodeDateTimeNow(3);
  print(animeInfo);
}
