import 'package:animetrace/dao/anime_dao.dart';
import 'package:animetrace/utils/episode.dart';
import 'package:animetrace/utils/log.dart';

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
        select distinct anime.anime_id, anime.anime_name, anime.anime_cover_url, anime.episode_start_number, anime.cal_episode_number_from_one
        from history, anime
        where date like '$date%' and history.anime_id = anime.anime_id
        order by date desc; -- 倒序
        ''');
    List<Anime> animes = [];
    for (var row in list) {
      animes.add(await AnimeDao.row2Bean(row));
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
      anime,
      reviewNumber,
      EpisodeUtil.getFixedEpisodeNumber(anime, startEpisodeNumber),
      EpisodeUtil.getFixedEpisodeNumber(anime, endEpisodeNumber),
    );
    return record;
  }

  static Future<int> getCount() async {
    var list = await SqliteUtil.database.rawQuery('''
    select count(*) cnt from history
    ''');
    return list[0]["cnt"] as int;
  }

  /// 第一条观看的历史记录
  static Future<Map<String, dynamic>?> getFirstHistory() async {
    Log.info('sql: getFirstHistory');

    var cols = await SqliteUtil.database.rawQuery('''
      select min(date) min_date, anime_id from history
      where date not like '0000%';
    ''');
    if (cols.isEmpty) return null;

    var col = cols.first;
    var anime = await SqliteUtil.getAnimeByAnimeId(col['anime_id'] as int);
    return {
      'anime': anime,
      'date': col['min_date'],
    };
  }

  /// 最近观看的动漫
  static Future<List<Anime>> recentWatchedAnimes({int day = 10}) async {
    List<Anime> animes = [];
    final rows = await SqliteUtil.database.rawQuery('''
      select anime_id, max(date) lastDate from history
      group by anime_id
      order by date desc limit $day
    ''');
    for (final row in rows) {
      final anime = await SqliteUtil.getAnimeByAnimeId(row['anime_id'] as int);
      anime.tempInfo = row['lastDate'] as String? ?? '';
      if (anime.isCollected()) animes.add(anime);
    }
    return animes;
  }

  /// 获取最大观看次数
  static Future<int> getMaxReviewNumber(int animeId) async {
    final rows = await SqliteUtil.database.rawQuery('''
      select max(review_number) max_review_number from history where anime_id = $animeId;
    ''');
    return SqliteUtil.firstRowColumnValue<int>(rows) ?? 1;
  }

  /// 获取指定回顾序号动漫的观看集数
  static Future<int> getAnimeWatchedCount(int animeId, int reviewNumber) async {
    final rows = await SqliteUtil.database.rawQuery('''
      select count(date) number from history
      where anime_id = $animeId and review_number = $reviewNumber;
    ''');
    return SqliteUtil.firstRowColumnValue<int>(rows) ?? 0;
  }

  /// 获取当前观看次数的最早日期
  static Future<String> getWatchedMinDate(int animeId, int reviewNumber) async {
    final rows = await SqliteUtil.database.rawQuery('''
      select min(date) from history
      where anime_id = $animeId and review_number = $reviewNumber and date not like '0000%';
    ''');
    return SqliteUtil.firstRowColumnValue<String>(rows) ?? '';
  }

  /// 获取当前观看次数的最晚日期
  static Future<String> getWatchedMaxDate(int animeId, int reviewNumber) async {
    final rows = await SqliteUtil.database.rawQuery('''
      select max(date) from history
      where anime_id = $animeId and review_number = $reviewNumber and date not like '0000%';
    ''');
    return SqliteUtil.firstRowColumnValue<String>(rows) ?? '';
  }
}
