import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/episode.dart';

class EpisodeNote {
  int episodeNoteId;
  Anime anime;
  Episode episode;
  String noteContent;
  List<String> imgLocalPaths;
  List<String> imgUrls;

  EpisodeNote({
    this.episodeNoteId = 0,
    required this.anime,
    required this.episode,
    this.noteContent = "",
    required this.imgLocalPaths,
    required this.imgUrls,
  });
  @override
  String toString() {
    return "${anime.animeName}-${episode.number}: $noteContent";
  }
}
