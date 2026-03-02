import 'package:animetrace/utils/sqlite_util.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class EpisodeDesc {
  int id; // 唯一id
  int animeId; // 动漫id
  int number; // 集编号(最小为1)
  String title; // 设置的标题
  bool hideDefault; // 是否隐藏原来的第number集
  double? rate; // 评分([0, 0.5, 1, ..., 5], null表示未评分)

  EpisodeDesc({
    required this.id,
    required this.animeId,
    required this.number,
    this.title = '',
    this.hideDefault = false,
    this.rate,
  });

  bool get notInsert => id <= 0;

  @override
  String toString() {
    return 'EpisodeDesc(id: $id, animeId: $animeId, number: $number, title: $title, showDefault: $hideDefault, rate: $rate)';
  }
}

class EpisodeDescDao {
  static Database get db => SqliteUtil.database;
  static const table = "episode_desc";
  static const columnId = "id";
  static const columnAnimeId = "anime_id";
  static const columnNumber = "number";
  static const columnTitle = "title";
  static const columnHideDefault = "hide_default";
  static const columnRate = "rate";
  static const columns = [
    columnId,
    columnAnimeId,
    columnNumber,
    columnTitle,
    columnHideDefault,
    columnRate,
  ];

  // 建表
  static createTable() async {
    // await db.execute('drop table $table');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS $table (
      $columnId             INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnAnimeId        INTEGER NOT NULL,
      $columnNumber         INTEGER NOT NULL,
      $columnTitle          TEXT NOT NULL,
      $columnHideDefault    INTEGER NOT NULL,
      $columnRate           REAL
    );
    ''');
    await _upgrade();
  }

  static EpisodeDesc row2bean(Map<String, Object?> map) {
    return EpisodeDesc(
      id: map[columnId] as int,
      animeId: map[columnAnimeId] as int,
      number: map[columnNumber] as int,
      title: map[columnTitle] as String,
      hideDefault: map[columnHideDefault] as int > 0 ? true : false,
      rate: map[columnRate] as double?,
    );
  }

  static Future<int> insert(EpisodeDesc episodeDesc) {
    return db.insert(table, {
      columnAnimeId: episodeDesc.animeId,
      columnNumber: episodeDesc.number,
      columnTitle: episodeDesc.title,
      columnHideDefault: episodeDesc.hideDefault ? 1 : 0,
      columnRate: episodeDesc.rate,
    });
  }

  static Future<int> update(EpisodeDesc episodeDesc) {
    final rate = episodeDesc.rate;
    if (rate != null) {
      assert(0 <= rate && rate <= 5, 'invalid rate: $rate ([0, 5])');
    }

    return db.update(
      table,
      {
        columnTitle: episodeDesc.title,
        columnHideDefault: episodeDesc.hideDefault ? 1 : 0,
        columnRate: rate,
      },
      where: '$columnId = ?',
      whereArgs: [episodeDesc.id],
    );
  }

  static Future<EpisodeDesc?> query(int animeId, int episodeNumber) async {
    var mapList = await db.query(
      table,
      columns: columns,
      where: '$columnAnimeId = ? and $columnNumber = ?',
      whereArgs: [animeId, episodeNumber],
    );

    if (mapList.isEmpty) {
      return null;
    } else {
      return row2bean(mapList.first);
    }
  }

  static Future<List<EpisodeDesc>> queryAll(int animeId) async {
    var mapList = await db.query(
      table,
      columns: columns,
      where: '$columnAnimeId = ?',
      whereArgs: [animeId],
    );

    return mapList.map((e) => row2bean(e)).toList();
  }

  static Future<void> _upgrade() async {
    await SqliteUtil.addColumnName(
      tableName: table,
      columnName: columnRate,
      columnType: 'REAL',
    );
  }
}
