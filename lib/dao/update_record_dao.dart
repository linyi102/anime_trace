import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/models/anime_update_record.dart';
import 'package:flutter_test_future/models/vo/update_record_vo.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/log.dart';

class UpdateRecordDao {
  static var database = SqliteUtil.database;

  static insert(AnimeUpdateRecord updateRecord) {
    Log.info("sql:insertUpdateRecord(updateRecord=$updateRecord)");
    database.insert("update_record", {
      "anime_id": updateRecord.animeId,
      "old_episode_cnt": updateRecord.oldEpisodeCnt,
      "new_episode_cnt": updateRecord.newEpisodeCnt,
      "manual_update_time": updateRecord.manualUpdateTime
    });
  }

  static Future<List<Object?>> batchInsert(
      List<AnimeUpdateRecord> updateRecords) async {
    var batchInsert = SqliteUtil.database.batch();
    for (var updateRecord in updateRecords) {
      Log.info("sql batch:insertUpdateRecord(updateRecord=$updateRecord)");
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
    Log.info("UpdateRecordDao: findAll(pageParams=$pageParams)");
    List<UpdateRecordVo> updateRecordVos = [];
    List<Map<String, Object?>> list = await SqliteUtil.database.rawQuery('''
    select substr(manual_update_time, 1, 10) day from update_record
    group by day
    order by day desc
    limit ${pageParams.pageSize} offset ${pageParams.getOffset()};
    ''');
    // await SqliteUtil.database.query("update_record",
    //     columns: ["manual_update_time"],
    //     limit: pageParams.pageSize,
    //     offset: pageParams.getOffset(),
    //     // 按日期分组，并倒序排序
    //     groupBy: "manual_update_time",
    //     orderBy: "manual_update_time desc");
    List<String> dates = [];
    Log.info("最近${pageParams.pageSize}(${list.length})个日期：");
    for (var map in list) {
      String date = map["day"] as String;
      dates.add(date);
      Log.info("📅 $date");
      List<Map<String, Object?>> updateRecordsMap =
          await SqliteUtil.database.rawQuery('''
          select * from update_record
          where manual_update_time like '$date%';
          ''');
      // 遍历该天的所有更新记录
      for (var updateRecordMap in updateRecordsMap) {
        int animeId = updateRecordMap["anime_id"] as int;
        UpdateRecordVo updateRecordVo = UpdateRecordVo(
            id: updateRecordMap["id"] as int,
            anime: await SqliteUtil.getAnimeByAnimeId(animeId),
            // 根据动漫id找到动漫
            oldEpisodeCnt: updateRecordMap["old_episode_cnt"] as int,
            newEpisodeCnt: updateRecordMap["new_episode_cnt"] as int,
            manualUpdateTime: date);
        Log.info(updateRecordVo.toString());
        updateRecordVos.add(updateRecordVo);
      }
    }
    return updateRecordVos;
  }
}
