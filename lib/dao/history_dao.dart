import 'package:flutter_test_future/utils/log.dart';

import '../models/anime.dart';
import '../models/anime_history_record.dart';
import '../models/history_plus.dart';
import '../models/params/page_params.dart';
import '../utils/sqlite_util.dart';

class HistoryDao {
  // 整体思路：先找到符合该日期的所有动漫id，然后根据动漫id去重，再根据动漫id得到观看的最小值和最大值
  // 新增回顾号列后，最小值和最大值应该属于同一回顾号
  static Future<List<HistoryPlus>> getHistoryPageable(
      {required PageParams pageParams, required int dateLength}) async {
    Log.info("sql: getHistoryPageable");
    // await Future.delayed(Duration(seconds: 2));
    // 获取有数据的最近几天/月
    List<Map<String, Object?>> dayList = await SqliteUtil.database.rawQuery('''
    select substr(date, 1, $dateLength) dateSubstr from history
    group by dateSubstr
    order by dateSubstr desc
    limit ${pageParams.pageSize} offset ${pageParams.getOffset()};
    ''');
    List<String> list = [];
    for (var map in dayList) {
      list.add(map['dateSubstr'] as String);
    }

    // 遍历这些日期，获取每个日期对应的records
    List<HistoryPlus> historys = [];
    for (var day in list) {
      List<AnimeHistoryRecord> records = await _getHistoryRecordsByDate(day);
      if (records.isNotEmpty) {
        historys.add(HistoryPlus(day, records));
      }
    }
    return historys;
  }

  static _getHistoryRecordsByDate(String date) async {
    var list = await SqliteUtil.database.rawQuery('''
        select distinct anime.anime_id, anime.anime_name, anime.anime_cover_url
        from history, anime
        where date like '$date%' and history.anime_id = anime.anime_id
        order by date desc; -- 倒序
        ''');
    List<Anime> animes = [];
    for (var item in list) {
      animes.add(Anime(
          animeId: item['anime_id'] as int,
          animeName: item['anime_name'] as String,
          animeEpisodeCnt: 0,
          animeCoverUrl: item['anime_cover_url'] as String? ?? ""));
    }

    List<AnimeHistoryRecord> records = [];
    if (animes.isEmpty) return records; // 没有观看记录时直接跳过

    // 对于每个动漫，找到当月观看的最小值和最大值
    // 如果该月存在多个回顾号，注意要挑选的最小值和最大值的回顾号一样
    // 因此需要先找出该月存在的该动漫的所有回顾号(注意去重)，对与每个回顾号
    // 都要找出min和max，并添加到records中
    for (var anime in animes) {
      // Log.info(anime);
      var reviewNumberList = await SqliteUtil.database.rawQuery('''
        select distinct review_number
        from history
        where date like '$date%' and anime_id = ${anime.animeId};
        ''');
      for (var reviewNumberElem in reviewNumberList) {
        int reviewNumber = reviewNumberElem['review_number'] as int;
        AnimeHistoryRecord record =
            await getRecordByAnimeIdAndReviewNumberAndDate(
                anime, reviewNumber, date);
        records.add(record);
      }
    }
    return records;
  }

  /// 传入anime而不是animeId是因为要构造record
  static Future<AnimeHistoryRecord> getRecordByAnimeIdAndReviewNumberAndDate(
      Anime anime, int reviewNumber, String date) async {
    var list = await SqliteUtil.database.rawQuery('''
          select min(episode_number) as start
          from history
          where date like '$date%' and anime_id = ${anime.animeId} and review_number = $reviewNumber;
          ''');
    int startEpisodeNumber = list[0]['start'] as int;
    list = await SqliteUtil.database.rawQuery('''
          select max(episode_number) as end
          from history
          where date like '$date%' and anime_id = ${anime.animeId} and review_number = $reviewNumber;
          ''');
    int endEpisodeNumber = list[0]['end'] as int;
    // Log.info("$date: [$startEpisodeNumber-$endEpisodeNumber]");
    AnimeHistoryRecord record = AnimeHistoryRecord(
        anime, reviewNumber, startEpisodeNumber, endEpisodeNumber);
    return record;
  }

  static Future<int> getCount() async {
    var list = await SqliteUtil.database.rawQuery('''
    select count(*) cnt from history
    ''');
    return list[0]["cnt"] as int;
  }
}
