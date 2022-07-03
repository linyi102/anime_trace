import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';

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
    return "animeId=$animeId, animeName=$animeName, animeEpisodeCnt=$animeEpisodeCnt, tagName=$tagName, checkedEpisodeCnt=$checkedEpisodeCnt, animeCoverUrl=$animeCoverUrl, animeUrl=$animeUrl, premiereTime=$premiereTime, animeDesc=${reduceStr(animeDesc)}, playStatus=$playStatus, category=$category, area=$area, ";
  }

  String reduceStr(String str) {
    return str.length > 15 ? str.substring(0, 15) : str;
  }

  String getAnimeInfoFirstLine() {
    var list = [];
    if (area.isNotEmpty) {
      list.add(area);
    }
    if (category.isNotEmpty) {
      list.add(category);
    }
    if (premiereTime.isNotEmpty) {
      list.add(premiereTime);
    }

    return list.join(" / ");
  }

  String getAnimeInfoSecondLine() {
    var list = [];
    list.add(ClimbAnimeUtil.getClimbWebsiteByAnimeUrl(animeUrl)?.name ?? "自定义");
    if (playStatus.isNotEmpty) {
      list.add(playStatus);
    }
    if (animeEpisodeCnt != -1) {
      list.add("$animeEpisodeCnt 集");
    }
    return list.join(" • ");
  }

  bool isCollected() {
    return animeId > 0;
    // return tagName.isNotEmpty;
  }

  Anime copy() {
    Anime anime = Anime(animeName: animeName, animeEpisodeCnt: animeEpisodeCnt);
    anime.animeId = animeId;
    anime.tagName = tagName;
    anime.animeDesc = animeDesc;
    anime.animeCoverUrl = animeCoverUrl;
    anime.checkedEpisodeCnt = checkedEpisodeCnt;
    anime.reviewNumber = reviewNumber;
    anime.animeUrl = animeUrl;
    anime.premiereTime = premiereTime;
    anime.nameAnother = nameAnother;
    anime.nameOri = nameOri;
    anime.authorOri = authorOri;
    anime.area = area;
    anime.category = category;
    anime.playStatus = playStatus;
    anime.productionCompany = productionCompany;
    anime.officialSite = officialSite;
    return anime;
  }
}
