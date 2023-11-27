import 'package:flutter_test_future/models/anime.dart';

class AnimeHistoryRecord {
  Anime anime;
  int reviewNumber;
  int startEpisodeNumber;
  int endEpisodeNumber;

  AnimeHistoryRecord(this.anime, this.reviewNumber, this.startEpisodeNumber,
      this.endEpisodeNumber);

  @override
  String toString() {
    return "[$startEpisodeNumber-$endEpisodeNumber] ${anime.animeName}";
  }

  assign(AnimeHistoryRecord record) {
    anime = record.anime;
    reviewNumber = record.reviewNumber;
    startEpisodeNumber = record.startEpisodeNumber;
    endEpisodeNumber = record.endEpisodeNumber;
  }
}
