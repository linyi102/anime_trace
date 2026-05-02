import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/anime.dart';
import '../models/series.dart';
import '../utils/log.dart';
import '../utils/sqlite_util.dart';
import 'series_dao.dart';

class AnimeSeriesDao {
  static Database get db => SqliteUtil.database;
  static const table = "anime_series";
  static const columnId = "id";
  static const columnAnimeId = "anime_id";
  static const columnSeriesId = "series_id";

  // 建表
  static createTable() async {
    AppLog.info('sql: create table $table');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS $table (
      $columnId         INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnAnimeId    INTEGER NOT NULL,
      $columnSeriesId   INTEGER NOT NULL
    );
    ''');
  }

  // 查询某个动漫下的所有系列id
  static Future<List<int>> getSeriesIdListByAnimeId(int animeId) async {
    // AppLog.info("sql:getSeriesIdListByAnimeId(animeId=$animeId)");
    // 先获取该动漫的所有系列id
    List<Map<String, Object?>> maps = await db.query(table,
        columns: [columnSeriesId],
        where: "$columnAnimeId = ?",
        whereArgs: [animeId]);
    // 再根据系列id查询完整系列信息
    List<int> seriesIdList = [];
    for (var map in maps) {
      int seriesId = map[columnSeriesId] as int;
      seriesIdList.add(seriesId);
    }

    return seriesIdList;
  }

  // 查询某个动漫下的所有系列
  static Future<List<Series>> getSeriesListByAnimeId(int animeId,
      {bool needAnimes = true}) async {
    AppLog.info("sql:getSeriesByAnimeId(animeId=$animeId)");
    // 先获取该动漫的所有系列id
    List<int> seriesIds = await getSeriesIdListByAnimeId(animeId);
    // 再根据系列id查询完整系列信息
    List<Series> seriesList = [];
    for (var seriesId in seriesIds) {
      Series series =
          await SeriesDao.getSeriesById(seriesId, needAnimes: needAnimes);
      if (series.isValid) {
        seriesList.add(series);
      }
    }

    return seriesList;
  }

  // 查询含有指定多个系列的所有动漫
  static Future<List<Anime>> getAnimesBySeriesIds(List<int> seriesIds) async {
    AppLog.info("sql:getAnimesBySeriesId(seriesIds=$seriesIds)");
    // 先获取该系列下的所有动漫id
    List<Map<String, Object?>> maps = await db.rawQuery('''
    SELECT anime_id
    FROM anime_series
    WHERE series_id in (${seriesIds.join(",")})
    GROUP BY anime_id
    HAVING COUNT(*) = ${seriesIds.length};
    ''');
    // 在根据动漫id查询完整动漫信息
    List<Anime> animes = [];
    for (var map in maps) {
      int animeId = map[columnAnimeId] as int;
      Anime anime = await SqliteUtil.getAnimeByAnimeId(animeId);
      // 如果没有找到动漫，则不添加(可能是因为之前删除了动漫，但没有删除系列列表里的添加记录)
      if (anime.isCollected()) {
        animes.add(anime);
      }
    }

    animes.sort(
      (a, b) {
        // 没有首播时间时，排序到最后面
        if (a.premiereTime.isEmpty || b.premiereTime.isEmpty) return -1;
        // 首播时间升序排序
        return a.premiereTime.compareTo(b.premiereTime);
      },
    );
    return animes;
  }

  // 某个动漫添加系列，返回新插入记录的id(id用不上)
  static Future<int> insertAnimeSeries(int animeId, int seriesId) async {
    AppLog.info("sql:insertAnimeSeries(animeId=$animeId, seriesId=$seriesId)");
    return await db.insert(table, {
      columnAnimeId: animeId,
      columnSeriesId: seriesId,
    });
  }

  static Future<bool> deleteAnimeSeries(int animeId, int seriesId) async {
    AppLog.info("sql:deleteAnimeSeries(animeId=$animeId, seriesId=$seriesId)");
    return (await db.delete(table,
            where: "$columnAnimeId = ? and $columnSeriesId = ?",
            whereArgs: [animeId, seriesId])) >
        0;
  }

  // 删除系列时，需要这里的相关信息，也可能还没有和任意一个动漫关联，所以不返回删除行数
  static Future<void> deleteBySeriesId(int seriesId) async {
    AppLog.info("sql:deleteBySeriesId(seriesId=$seriesId)");
    await db.delete(table, where: "$columnSeriesId = ?", whereArgs: [seriesId]);
  }
}
