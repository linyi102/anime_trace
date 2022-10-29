import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/models/anime_update_record.dart';
import 'package:flutter_test_future/models/vo/update_record_vo.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';

class UpdateRecordDao {
  static Future<List<Object?>> batchInsert(
      List<AnimeUpdateRecord> updateRecords) async {
    var batchInsert = SqliteUtil.database.batch();
    for (var updateRecord in updateRecords) {
      debugPrint("sql batch:insertUpdateRecord(updateRecord=$updateRecord)");
      batchInsert.insert("update_record", {
        "anime_id": updateRecord.animeId,
        "old_episode_cnt": updateRecord.oldEpisodeCnt,
        "new_episode_cnt": updateRecord.newEpisodeCnt,
        "manual_update_time": updateRecord.manualUpdateTime
      });
    }
    return await batchInsert.commit(noResult: true, continueOnError: true);
  }

  // 先获取最近更新的pageSize个日期，然后循环查询当前日期下的所有记录
  static Future<List<UpdateRecordVo>> findAll(PageParams pageParams) async {
    debugPrint("UpdateRecordDao: findAll(pageParams=$pageParams)");
    List<UpdateRecordVo> updateRecordVos = [];
    List<Map<String, Object?>> datesMap =
        await SqliteUtil.database.query("update_record",
            columns: ["manual_update_time"],
            limit: pageParams.pageSize,
            offset: pageParams.getOffsetWhenIndexStartZero(),
            // 按日期分组，并倒序排序
            groupBy: "manual_update_time",
            orderBy: "manual_update_time desc");
    List<String> dates = [];
    debugPrint("最近${pageParams.pageSize}(${datesMap.length})个日期：");
    for (var dateMap in datesMap) {
      String date = dateMap["manual_update_time"] as String;
      dates.add(date);
      debugPrint("📅 $date");
      List<Map<String, Object?>> updateRecordsMap =
          await SqliteUtil.database.query(
        "update_record",
        where: "manual_update_time = ?",
        whereArgs: [date],
      );
      // 遍历该天的所有更新记录
      for (var updateRecordMap in updateRecordsMap) {
        int animeId = updateRecordMap["anime_id"] as int;
        UpdateRecordVo updateRecordVo = UpdateRecordVo(
            id: updateRecordMap["id"] as int,
            anime: await SqliteUtil.getAnimeByAnimeId(animeId), // 根据动漫id找到动漫
            oldEpisodeCnt: updateRecordMap["old_episode_cnt"] as int,
            newEpisodeCnt: updateRecordMap["new_episode_cnt"] as int,
            manualUpdateTime: date);
        debugPrint(updateRecordVo.toString());
        updateRecordVos.add(updateRecordVo);
      }
    }
    return updateRecordVos;
  }
}
