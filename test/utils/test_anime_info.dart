// ignore_for_file: avoid_print

import 'package:flutter_test_future/utils/anime_info.dart';

main(List<String> args) {
  AnimeInfo animeInfo = AnimeInfo("anime_name");
  for (int i = 0; i < 6; ++i) {
    animeInfo.addEpisodeInfo();
  }
  print(animeInfo);
  animeInfo.setEpisodeDateTimeNow(1);
  animeInfo.setEpisodeDateTimeNow(3);
  print(animeInfo);
}
