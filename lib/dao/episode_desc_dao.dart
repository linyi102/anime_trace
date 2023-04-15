import 'package:flutter_test_future/utils/sqlite_util.dart';

class EpisodeDesc {
  int id; // 唯一id
  int animeId; // 动漫id
  int number; // 集编号(最小为1)
  String title; // 设置的标题
  bool hideDefault; // 是否隐藏原来的第number集

  EpisodeDesc({
    required this.id,
    required this.animeId,
    required this.number,
    required this.title,
    required this.hideDefault,
  });

  bool get notInsert => id <= 0;

  @override
  String toString() {
    return 'EpisodeDesc(id: $id, animeId: $animeId, number: $number, title: $title, showDefault: $hideDefault)';
  }
}

class EpisodeDescDao {
  static final db = SqliteUtil.database;
  static const table = "episode_desc";
  static const columnId = "id";
  static const columnAnimeId = "anime_id";
  static const columnNumber = "number";
  static const columnTitle = "title";
  static const columnHideDefault = "hide_default";
  static const columns = [
    columnId,
    columnAnimeId,
    columnNumber,
    columnTitle,
    columnHideDefault,
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
      $columnHideDefault    INTEGER NOT NULL
    );
    ''');
  }

  static EpisodeDesc row2bean(Map<String, Object?> map) {
    return EpisodeDesc(
      id: map[columnId] as int,
      animeId: map[columnAnimeId] as int,
      number: map[columnNumber] as int,
      title: map[columnTitle] as String,
      hideDefault: map[columnHideDefault] as int > 0 ? true : false,
    );
  }

  static Future<int> insert(EpisodeDesc episodeDesc) {
    return db.insert(table, {
      columnAnimeId: episodeDesc.animeId,
      columnNumber: episodeDesc.number,
      columnTitle: episodeDesc.title,
      columnHideDefault: episodeDesc.hideDefault ? 1 : 0,
    });
  }

  static Future<int> update(EpisodeDesc episodeDesc) {
    return db.update(
      table,
      {
        columnTitle: episodeDesc.title,
        columnHideDefault: episodeDesc.hideDefault ? 1 : 0,
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
}
