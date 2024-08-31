import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/episode.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';

class Note {
  int id;
  Anime anime;
  Episode episode;
  String noteContent;
  List<RelativeLocalImage> relativeLocalImages;
  List<String> imgUrls;
  String createTime;
  String updateTime;

  Note({
    this.id = 0,
    required this.anime,
    required this.episode,
    this.noteContent = "",
    required this.relativeLocalImages,
    required this.imgUrls,
    this.createTime = "",
    this.updateTime = "",
  });

  bool get isEmpty =>
      noteContent.isEmpty && relativeLocalImages.isEmpty && imgUrls.isEmpty;

  @override
  String toString() {
    return "${anime.animeName}-${episode.number}: $noteContent";
  }

  static Note createRateNote(Anime anime) {
    return Note(
        anime: anime,
        episode: Episode(0, 1), // 第0集作为评价
        relativeLocalImages: [],
        imgUrls: []);
  }

  static Note createEpisodeNote(Anime anime, Episode episode) {
    return Note(
        anime: anime, episode: episode, relativeLocalImages: [], imgUrls: []);
  }
}
