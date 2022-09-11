import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/episode.dart';
import 'package:flutter_test_future/classes/relative_local_image.dart';

class EpisodeNote {
  int episodeNoteId;
  Anime anime;
  Episode episode;
  String noteContent;
  List<RelativeLocalImage> relativeLocalImages;
  List<String> imgUrls;
  String createTime;
  String updateTime;

  EpisodeNote({
    this.episodeNoteId = 0,
    required this.anime,
    required this.episode,
    this.noteContent = "",
    required this.relativeLocalImages,
    required this.imgUrls,
    this.createTime = "",
    this.updateTime = "",
  });
  @override
  String toString() {
    return "${anime.animeName}-${episode.number}: $noteContent";
  }
}
