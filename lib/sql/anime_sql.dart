class AnimeSql {
  int animeId;
  String animeName;
  int animeEpisodeCnt;
  String tagName;

  int checkedEpisodeCnt;

  AnimeSql(
      {this.animeId = 0,
      required this.animeName,
      required this.animeEpisodeCnt,
      this.tagName = "",
      this.checkedEpisodeCnt = 0});
}
