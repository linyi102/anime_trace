import 'package:flutter_test_future/classes/anime.dart';

class Record {
  Anime anime;
  int startEpisodeNumber;
  int endEpisodeNumber;

  Record(this.anime, this.startEpisodeNumber, this.endEpisodeNumber);

  @override
  String toString() {
    return "[$startEpisodeNumber-$endEpisodeNumber] ${anime.animeName}";
  }
}
