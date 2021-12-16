// ignore_for_file: avoid_print

import 'package:flutter_test_future/utils/episode.dart';

main(List<String> args) {
  Episode episodeInfo = Episode(1);
  episodeInfo.dateTime = DateTime.now().toString();
  print(episodeInfo.getDate());
}
