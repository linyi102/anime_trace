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

  @override
  String toString() {
    return "${anime.animeName}-${episode.number}: $noteContent";
  }
}
