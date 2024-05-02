import 'package:flutter_test_future/models/enum/play_status.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/time_util.dart';

class Anime {
  int animeId;
  String animeName;
  int animeEpisodeCnt; // 总集数
  int episodeStartNumber; // 起始集
  bool calEpisodeNumberFromOne; // 从第1集开始计算
  String tagName;
  String animeDesc;
  String animeCoverUrl;
  int rate;

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

  bool climbFinished;
  String? tempInfo; // 临时信息，例如查询豆瓣用户收藏
  bool hasJoinedSeries;

  Anime({
    this.animeId = 0,
    required this.animeName,
    this.animeEpisodeCnt = 0,
    this.episodeStartNumber = 1,
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
    this.rate = 0,
    this.climbFinished = false,
    this.tempInfo,
    this.hasJoinedSeries = false,
    this.calEpisodeNumberFromOne = false,
  });

  DateTime? get premiereDateTime => DateTime.tryParse(premiereTime);

  String getAnimeInfoFirstLine() {
    var list = [];
    if (area.isNotEmpty) {
      list.add(area);
    }
    if (category.isNotEmpty) {
      list.add(category);
    }
    if (premiereTime.isNotEmpty && premiereTime != 'null') {
      String timeInfo = premiereTime;
      int? weekday = DateTime.tryParse(premiereTime)?.weekday;
      if (weekday != null && getPlayStatus() == PlayStatus.playing) {
        timeInfo += ' 周${TimeUtil.getChineseWeekdayByNumber(weekday)}';
      }
      list.add(timeInfo);
    }

    return list.join(" / ");
  }

  String getAnimeInfoSecondLine() {
    var list = [];

    list.add(getAnimeSource());

    PlayStatus playStatus = getPlayStatus();
    if (playStatus != PlayStatus.unknown) {
      list.add(getPlayStatus().text);
    }

    if (animeEpisodeCnt != -1) {
      list.add("$animeEpisodeCnt集");
    }
    return list.join(" • ");
  }

  String getAnimeSource() {
    return ClimbAnimeUtil.getClimbWebsiteByAnimeUrl(animeUrl)?.name ?? "自定义";
  }

  PlayStatus getPlayStatus() => PlayStatus.text2PlayStatus(playStatus);

  // 因为封面可能是网络图片，也可能是本地图片，如果是本地图片，那么需要将相对路径转为绝对路径
  String getCommonCoverUrl() {
    // 如果是空的，则返回空字符串
    if (animeCoverUrl.isEmpty) {
      return "";
    }
    // 然后再区分网络和本地图片
    if (animeCoverUrl.startsWith("http")) {
      return animeCoverUrl;
    } else {
      return ImageUtil.getAbsoluteCoverImagePath(animeCoverUrl);
    }
  }

  bool isCollected() {
    return animeId > 0;
    // return tagName.isNotEmpty;
  }

  Anime copyWith({
    int? animeId,
    String? animeName,
    int? animeEpisodeCnt,
    int? episodeStartNumber,
    bool? calEpisodeNumberFromOne,
    String? tagName,
    String? animeDesc,
    String? animeCoverUrl,
    int? rate,
    int? checkedEpisodeCnt,
    int? reviewNumber,
    String? animeUrl,
    String? premiereTime,
    String? nameAnother,
    String? nameOri,
    String? authorOri,
    String? area,
    String? category,
    String? playStatus,
    String? productionCompany,
    String? officialSite,
    bool? climbFinished,
    String? tempInfo,
    bool? hasJoinedSeries,
  }) {
    return Anime(
      animeId: animeId ?? this.animeId,
      animeName: animeName ?? this.animeName,
      animeEpisodeCnt: animeEpisodeCnt ?? this.animeEpisodeCnt,
      episodeStartNumber: episodeStartNumber ?? this.episodeStartNumber,
      calEpisodeNumberFromOne:
          calEpisodeNumberFromOne ?? this.calEpisodeNumberFromOne,
      tagName: tagName ?? this.tagName,
      animeDesc: animeDesc ?? this.animeDesc,
      animeCoverUrl: animeCoverUrl ?? this.animeCoverUrl,
      rate: rate ?? this.rate,
      checkedEpisodeCnt: checkedEpisodeCnt ?? this.checkedEpisodeCnt,
      reviewNumber: reviewNumber ?? this.reviewNumber,
      animeUrl: animeUrl ?? this.animeUrl,
      premiereTime: premiereTime ?? this.premiereTime,
      nameAnother: nameAnother ?? this.nameAnother,
      nameOri: nameOri ?? this.nameOri,
      authorOri: authorOri ?? this.authorOri,
      area: area ?? this.area,
      category: category ?? this.category,
      playStatus: playStatus ?? this.playStatus,
      productionCompany: productionCompany ?? this.productionCompany,
      officialSite: officialSite ?? this.officialSite,
      climbFinished: climbFinished ?? this.climbFinished,
      tempInfo: tempInfo ?? this.tempInfo,
      hasJoinedSeries: hasJoinedSeries ?? this.hasJoinedSeries,
    );
  }

  @override
  String toString() {
    return "Anime=[animeId=$animeId, animeName=$animeName, "
        "animeEpisodeCnt=$animeEpisodeCnt, episodeStartNumber=$episodeStartNumber, tagName=$tagName, "
        "checkedEpisodeCnt=$checkedEpisodeCnt, animeCoverUrl=$animeCoverUrl, "
        "animeUrl=$animeUrl, premiereTime=$premiereTime, "
        "animeDesc=${reduceStr(animeDesc)}, playStatus=$playStatus, "
        "category=$category, area=$area, rate=$rate]";
  }

  String reduceStr(String str) {
    return str.length > 15 ? str.substring(0, 15) : str;
  }
}
