import 'package:flutter_test_future/dao/label_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/label.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../utils/sqlite_util.dart';

class AnimeLabelDao {
  static final db = SqliteUtil.database;
  static const table = "anime_label";
  static const columnId = "id";
  static const columnAnimeId = "anime_id";
  static const columnLabelId = "label_id";

  // 建表
  static createTable() async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS $table (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      anime_id   INTEGER NOT NULL,
      label_id   INTEGER NOT NULL
    );
    ''');
  }

  // 查询某个动漫下的所有标签
  static Future<List<Label>> getLabelsByAnimeId(int animeId) async {
    Log.info("sql:deleteAnimeLabel(animeId=$animeId)");
    // 先获取该动漫的所有标签id
    List<Map<String, Object?>> maps = await db.query(table,
        columns: [columnLabelId],
        where: "$columnAnimeId = ?",
        whereArgs: [animeId]);
    // 再根据标签id查询完整标签信息
    List<Label> labels = [];
    for (var map in maps) {
      int labelId = map[columnLabelId] as int;
      Label label = await LabelDao.getLabelById(labelId);
      if (label.isValid) {
        labels.add(label);
      }
    }

    return labels;
  }

  // 查询某个标签下的所有动漫
  static Future<List<Anime>> getAnimesByLabelId(int labelId) async {
    Log.info("sql:getAnimesByLabelId(labelId=$labelId)");
    // 先获取该标签下的所有动漫id
    List<Map<String, Object?>> maps = await db.query(table,
        columns: [columnAnimeId],
        where: "$columnLabelId = ?",
        whereArgs: [labelId]);
    // 在根据动漫id查询完整动漫信息
    List<Anime> animes = [];
    for (var map in maps) {
      int animeId = map[columnAnimeId] as int;
      animes.add(await SqliteUtil.getAnimeByAnimeId(animeId));
    }

    return animes;
  }

  // 查询含有指定多个标签的所有动漫
  static Future<List<Anime>> getAnimesByLabelIds(List<int> labelIds) async {
    Log.info("sql:getAnimesByLabelId(labelIds=$labelIds)");
    // 先获取该标签下的所有动漫id
    List<Map<String, Object?>> maps = await db.rawQuery('''
    SELECT anime_id
    FROM anime_label
    WHERE label_id in (${labelIds.join(",")})
    GROUP BY anime_id
    HAVING COUNT(*) = ${labelIds.length};
    ''');
    // 在根据动漫id查询完整动漫信息
    List<Anime> animes = [];
    for (var map in maps) {
      int animeId = map[columnAnimeId] as int;
      animes.add(await SqliteUtil.getAnimeByAnimeId(animeId));
    }

    return animes;
  }

  // 某个动漫添加标签，返回新插入记录的id(id用不上)
  static Future<int> insertAnimeLabel(int animeId, int labelId) async {
    Log.info("sql:insertAnimeLabel(animeId=$animeId, labelId=$labelId)");
    return await db.insert(table, {
      columnAnimeId: animeId,
      columnLabelId: labelId,
    });
  }

  // 某个动漫移除标签，不能根据id，因为动漫详细页存储的是List<Label>，和anime_label表的id没有关系
  // static Future<bool> deleteAnimeLabel(int id) async {
  //   return (await db.delete(table, where: "$columnId = ?", whereArgs: [id])) >
  //       0;
  // }
  static Future<bool> deleteAnimeLabel(int animeId, int labelId) async {
    Log.info("sql:deleteAnimeLabel(animeId=$animeId, labelId=$labelId)");
    return (await db.delete(table,
            where: "$columnAnimeId = ? and $columnLabelId = ?",
            whereArgs: [animeId, labelId])) >
        0;
  }

  // 删除标签时，需要这里的相关信息，也可能还没有和任意一个动漫关联，所以不返回删除行数
  static Future<void> deleteByLabelId(int labelId) async {
    Log.info("sql:deleteByLabelId(labelId=$labelId)");
    await db.delete(table, where: "$columnLabelId = ?", whereArgs: [labelId]);
  }
}
