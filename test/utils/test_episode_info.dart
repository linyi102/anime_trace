// ignore_for_file: avoid_print

import 'package:flutter_test_future/utils/episode_info.dart';

main(List<String> args) {
  EpisodeInfo episodeInfo = EpisodeInfo(1);
  episodeInfo.setDateTimeNow();
  print(episodeInfo.getDate());
}
