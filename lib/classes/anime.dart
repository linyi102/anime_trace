class Anime {
  int animeId;
  String animeName;
  int animeEpisodeCnt;
  String tagName;

  int checkedEpisodeCnt;

  Anime(
      {this.animeId = 0,
      required this.animeName,
      required this.animeEpisodeCnt,
      this.tagName = "",
      this.checkedEpisodeCnt = 0});

  @override
  String toString() {
    return "animeId=$animeId, animeName=$animeName, animeEpisodeCnt=$animeEpisodeCnt, tagName=$tagName, checkedEpisodeCnt=$checkedEpisodeCnt";
  }
}
