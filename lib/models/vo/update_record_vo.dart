import 'package:animetrace/models/anime.dart';

class UpdateRecordVo {
  int id;
  Anime anime;
  int oldEpisodeCnt;
  int newEpisodeCnt;
  String manualUpdateTime; // 详细时间
  String manualUpdateDate() =>
      manualUpdateTime.substring(0, 10); // 日期，作为map的key

  UpdateRecordVo(
      {required this.id,
      required this.anime,
      this.oldEpisodeCnt = 0,
      this.newEpisodeCnt = 0,
      this.manualUpdateTime = ""});

  @override
  String toString() {
    return "UpdateRecordVo[id=$id,anime=[id=${anime.animeId},name=${anime.animeName}],oldEpisodeCnt=$oldEpisodeCnt,newEpisodeCnt=$newEpisodeCnt,manualUpdateTime=$manualUpdateTime]";
  }
}
