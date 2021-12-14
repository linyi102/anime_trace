import 'package:flutter_test_future/utils/anime.dart';

class AnimeAndEpisode {
  Anime anime;
  int episodeNumber;

  AnimeAndEpisode(this.anime, this.episodeNumber);

  @override
  String toString() {
    return "${anime.name}, $episodeNumber\n";
  }
}

class DayRecord {
  List<AnimeAndEpisode> animeRecord = [];

  void addRecord(Anime anime, int episodeNumber) {
    animeRecord.add(AnimeAndEpisode(anime, episodeNumber));
  }

  void removeRecord(Anime anime, int episodeNumber) {
    animeRecord.removeWhere((element) =>
        element.anime == anime && element.episodeNumber == episodeNumber);
  }

  @override
  String toString() {
    StringBuffer stringBuffer = StringBuffer();
    for (AnimeAndEpisode animeAndEpisode in animeRecord) {
      stringBuffer.write("$animeAndEpisode");
    }
    return stringBuffer.toString();
  }
}
