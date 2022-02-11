class Anime {
  int animeId;
  String animeName;
  int animeEpisodeCnt;
  String tagName;
  String animeDesc;
  String animeCoverUrl;

  int checkedEpisodeCnt;
  int reviewNumber;

  Anime(
      {this.animeId = 0,
      required this.animeName,
      required this.animeEpisodeCnt,
      this.tagName = "",
      this.animeCoverUrl = "",
      this.checkedEpisodeCnt = 0,
      this.animeDesc = "",
      this.reviewNumber = 1});

  @override
  String toString() {
    return "animeId=$animeId, animeName=$animeName, animeEpisodeCnt=$animeEpisodeCnt, tagName=$tagName, checkedEpisodeCnt=$checkedEpisodeCnt";
  }
}
