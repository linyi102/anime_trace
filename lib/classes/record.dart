import 'package:flutter_test_future/classes/anime.dart';

class Record {
  Anime anime;
  int reviewNumber;
  int startEpisodeNumber;
  int endEpisodeNumber;

  Record(this.anime, this.reviewNumber, this.startEpisodeNumber,
      this.endEpisodeNumber);

  @override
  String toString() {
    return "[$startEpisodeNumber-$endEpisodeNumber] ${anime.animeName}";
  }
}
