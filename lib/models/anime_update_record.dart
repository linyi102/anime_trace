import 'package:animetrace/models/vo/update_record_vo.dart';

import 'anime.dart';

class AnimeUpdateRecord {
  int id;
  int animeId;
  int oldEpisodeCnt;
  int newEpisodeCnt;
  String manualUpdateTime;

  AnimeUpdateRecord(
      {required this.animeId,
      this.id = 0,
      this.oldEpisodeCnt = 0,
      this.newEpisodeCnt = 0,
      this.manualUpdateTime = ""});

  @override
  String toString() {
    return "UpdateRecord[id=$id,animeId=$animeId,oldEpisodeCnt=$oldEpisodeCnt,newEpisodeCnt=$newEpisodeCnt,manualUpdateTime=$manualUpdateTime]";
  }

  UpdateRecordVo toVo(Anime anime) {
    UpdateRecordVo updateRecordVo = UpdateRecordVo(
        id: id,
        anime: anime, // id转为anime
        oldEpisodeCnt: oldEpisodeCnt,
        newEpisodeCnt: newEpisodeCnt,
        manualUpdateTime: manualUpdateTime);
    return updateRecordVo;
  }
}
