import '../models/series.dart';
import '../utils/log.dart';
import '../utils/sqlite_util.dart';
import 'anime_series_dao.dart';

class SeriesDao {
  static final db = SqliteUtil.database;
  static const table = "series";
  static const columnId = "id";
  static const columnName = "name";
  static const columnDesc = "desc";
  static const columnCoverUrl = "cover_url";
  static const columnCreateTime = "create_time";
  static const columnUpdateTime = "update_time";

  // 建表
  static createTable() async {
    Log.info('sql:create table $table');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS $table (
      $columnId          INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnName        TEXT NOT NULL,
      $columnDesc        TEXT NOT NULL,
      $columnCoverUrl    TEXT NOT NULL,
      $columnCreateTime  TEXT NOT NULL,
      $columnUpdateTime  TEXT NOT NULL
    );
    ''');
  }

  // 新建系列，并返回新插入记录的id，返回0表示插入失败
  static Future<int> insert(Series series) async {
    Log.info("sql:insert($series)");
    var now = DateTime.now().toString();
    // 插入除id以外的信息(因为id自增)
    return await db.insert(table, {
      columnName: series.name,
      columnDesc: series.desc,
      columnCoverUrl: series.coverUrl,
      columnCreateTime: now,
      columnUpdateTime: now,
    });
  }

  static Future<int> delete(int id) async {
    Log.info("sql:delete($id)");
    // 先删除动漫系列表中有该系列的记录
    await AnimeSeriesDao.deleteBySeriesId(id);
    // 再删除该系列
    return await db.delete(table, where: "$columnId = ?", whereArgs: [id]);
  }

  static Future<int> update(int id, String newName, String newDesc) async {
    Log.info("sql:update(id=$id, newName=$newName)");
    var now = DateTime.now().toString();
    return await db.rawUpdate('''
    update $table set $columnName = '$newName', $columnDesc = '$newDesc', $columnUpdateTime = '$now' where $columnId = $id;
    ''');
  }

  // 获取所有系列列表
  static Future<List<Series>> getAllSeries() async {
    Log.info("sql:getAllSeries");
    List<Map<String, Object?>> maps = await db.query(table);
    List<Series> seriesList = maps.map((e) => Series.fromMap(e)).toList();
    // 获取每个系列中的动漫
    for (var series in seriesList) {
      series.animes = await AnimeSeriesDao.getAnimesBySeriesIds([series.id]);
    }
    return seriesList;
  }

  // 根据id获取系列
  static Future<Series> getSeriesById(int id) async {
    Log.info("sql:getSeriesById(id=$id)");
    List<Map<String, Object?>> maps =
        await db.query(table, where: "$columnId = ?", whereArgs: [id]);

    if (maps.isNotEmpty) {
      var series = Series.fromMap(maps[0]);
      series.animes = await AnimeSeriesDao.getAnimesBySeriesIds([series.id]);
      return series;
    } else {
      return Series.noneLabel();
    }
  }

  // 搜索系列
  static Future<List<Series>> searchSeries(String kw) async {
    Log.info("sql:searchSeries(kw=$kw)");
    List<Map<String, Object?>> maps = await db.rawQuery('''
    select * from $table where $columnName like '%$kw%';
    ''');
    var seriesList = maps.map((e) => Series.fromMap(e)).toList();
    // 获取每个系列中的动漫
    for (var series in seriesList) {
      series.animes = await AnimeSeriesDao.getAnimesBySeriesIds([series.id]);
    }
    return seriesList;
  }

  // 查询是否存在系列名
  static Future<bool> existSeriesName(String name) async {
    Log.info("sql:existSeriesName(name=$name)");
    return (await db.query(table, where: "$columnName = ?", whereArgs: [name]))
        .isNotEmpty;
  }
}
