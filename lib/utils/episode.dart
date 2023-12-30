import 'package:flutter_test_future/models/anime.dart';

class EpisodeUtil {
  static int getFixedEpisodeNumber(Anime anime, int episodeNumber) {
    if (anime.calEpisodeNumberFromOne) {
      return episodeNumber;
    }

    return anime.episodeStartNumber + episodeNumber - 1;
  }

  static int getFakeEpisodeStartNumber(Anime anime) {
    if (anime.calEpisodeNumberFromOne) {
      return 1;
    }
    return anime.episodeStartNumber;
  }
}
