import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';

import '../models/anime.dart';

class AnimeDao {
  // 查询某个搜索源下的所有动漫
  static Future<List<Anime>> getAnimesBySourceKeyword(
      String sourceKeyword) async {
    List<Anime> animes = [];

    var db = SqliteUtil.database;
    // id用于表示动漫，name和cover用于显示，url用于确认是否已迁移
    List<Map<String, Object?>> list = await db.rawQuery('''
    select anime_id, anime_name, anime_cover_url, anime_url
    from anime
    where anime_url like '%$sourceKeyword%';
    ''');
    debugPrint("查询$sourceKeyword下的所有动漫：");
    for (Map row in list) {
      Anime anime = Anime(
          animeId: row['anime_id'],
          animeName: row['anime_name'],
          animeCoverUrl: row['anime_cover_url'],
          animeUrl: row['anime_url']);
      debugPrint(anime.toString());
      animes.add(anime);
    }

    return animes;
  }

  // 查询某个动漫的动漫网址
  static Future<String> getAnimeUrlById(int animeId) async {
    var db = SqliteUtil.database;
    var list = await db.rawQuery('''
    select anime_url
    from anime
    where anime_id = $animeId
    ''');
    for (Map row in list) {
      // 返回第一行的网址列
      return row['anime_url'] ?? '';
    }
    return '';
  }
}
