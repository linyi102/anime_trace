class Anime {
  int animeId;
  String animeName;
  int animeEpisodeCnt;
  String tagName;
  String animeDesc;
  String animeCoverUrl;

  int checkedEpisodeCnt;
  int reviewNumber;
  String animeUrl; // 动漫网址

  String premiereTime;
  String nameAnother;
  String nameOri;
  String authorOri;
  String area;
  String category;
  String playStatus;
  String productionCompany;
  String officialSite;

  Anime({
    this.animeId = 0,
    required this.animeName,
    required this.animeEpisodeCnt,
    this.tagName = "",
    this.animeCoverUrl = "",
    this.checkedEpisodeCnt = 0,
    this.animeDesc = "",
    this.reviewNumber = 1,
    this.animeUrl = "",
    this.premiereTime = "",
    this.nameAnother = "",
    this.nameOri = "",
    this.authorOri = "",
    this.area = "",
    this.category = "",
    this.playStatus = "",
    this.productionCompany = "",
    this.officialSite = "",
  });

  @override
  String toString() {
    return "animeId=$animeId\nanimeName=$animeName\nanimeEpisodeCnt=$animeEpisodeCnt\ntagName=$tagName\ncheckedEpisodeCnt=$checkedEpisodeCnt\nanimeCoverUrl=$animeCoverUrl\nanimeUrl=$animeUrl\npremiereTime=$premiereTime\nanimeDesc=$animeDesc\nplayStatus=$playStatus\ncategory=$category\narea=$area\n";
  }

  String getSubTitle() {
    var list = [];
    if (area.isNotEmpty) {
      list.add(area);
    }
    if (playStatus.isNotEmpty) {
      list.add(playStatus);
    }
    if (category.isNotEmpty) {
      list.add(category);
    }
    if (animeEpisodeCnt != -1) {
      list.add("$animeEpisodeCnt 集");
    }
    return list.join(" / ");
  }

  bool isCollected() {
    return animeId > 0;
    // return tagName.isNotEmpty;
  }
}
