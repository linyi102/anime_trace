import 'package:flutter_test_future/utils/anime.dart';

class AnimeList {
  List<Anime> _animeList = [];
  static AnimeList? _single;

  AnimeList._();

  static AnimeList getInstance() {
    return _single ??= AnimeList._();
  }

  void addAnime(String name) {
    _animeList.add(Anime(name));
  }

  void removeAnime(String name) {
    _animeList.removeWhere((element) => element.name == name);
  }
}
