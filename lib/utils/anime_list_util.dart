import 'package:flutter_test_future/utils/anime.dart';
import 'package:flutter_test_future/utils/tags.dart';

class AnimeListUtil {
  // 单例模式
  static AnimeListUtil? _single;

  AnimeListUtil._();

  static AnimeListUtil getInstance() {
    return _single ??= AnimeListUtil._();
  }

  // final List<Anime> _animeList = [];
  // 拾 途 终 搁 弃
  // 收集 途中 终点 搁置 放弃
  final Map<String, List<Anime>> _animeLists = {
    tags[0]: [],
    tags[1]: [],
    tags[2]: [],
    tags[3]: [],
    tags[4]: []
  };

  void addAnimeByNameAndTag(String name, String tag) {
    _animeLists[tag]!.add(Anime(name, tag: tag));
  }

  void addAnime(Anime anime) {
    _animeLists[anime.tag]!.add(anime);
  }

  List<Anime>? getAnimeListByTag(String tag) {
    return _animeLists[tag];
  }

  void moveAnime(Anime anime, String oldTag, String newTag) {
    _animeLists[oldTag]!.removeWhere((element) => element.name == anime.name);
    _animeLists[newTag]!.add(anime);
  }
}
