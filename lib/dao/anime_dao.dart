import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../models/anime.dart';

class AnimeDao {
  static final db = SqliteUtil.database;

  static Future<List<Anime>> getAllAnimes() async {
    Log.info("sql: getAllAnimes");

    var list = await db.rawQuery('''
    select * from anime;
    ''');

    List<Anime> res = [];
    for (var element in list) {
      res.add(Anime(
        // 其他信息是为了更新时作为oldAnime赋值给newAnime，以避免更新后有些属性为空串
        animeId: element['anime_id'] as int,
        animeName: element['anime_name'] as String,
        animeEpisodeCnt: element['anime_episode_cnt'] as int,
        // 更新前的集数
        animeDesc: element['anime_desc'] as String? ?? "",
        // 如果为null，则返回空串
        animeCoverUrl: element['anime_cover_url'] as String? ?? "",
        tagName: element['tag_name'] as String,
        reviewNumber: 1,
        premiereTime: element['premiere_time'] as String? ?? "",
        nameOri: element['name_ori'] as String? ?? "",
        nameAnother: element['name_another'] as String? ?? "",
        authorOri: element['author_ori'] as String? ?? "",
        area: element['area'] as String? ?? "",
        playStatus: element['play_status'] as String? ?? "",
        // 获取所有动漫后过滤掉更新未完结的动漫信息
        productionCompany: element['production_company'] as String? ?? "",
        officialSite: element['official_site'] as String? ?? "",
        category: element['category'] as String? ?? "",
        animeUrl: element['anime_url'] as String? ?? "", // 爬取网页更新详细信息
      ));
    }
    return res;
  }

  /// 清除简介
  static Future<bool> clearAllAnimeDesc() async {
    await db.rawUpdate('''
    update anime set anime_desc = null;
    ''');
    // 消除空闲页，否则数据库文件大小没有变化。注意不要放在rawUpdate中，否则Android端没有变化(Windows端文件却变小了)
    await db.execute('vacuum');
    return true;
  }

  /// 获取所有未完结动漫
  static Future<List<Anime>> getAllNeedUpdateAnimes() async {
    List<Anime> animes = await getAllAnimes();
    List<Anime> needUpdateAnimes = [];

    for (var anime in animes) {
      // 跳过完结动漫、豆瓣、bangumi、自定义动漫(也就是没有动漫地址)
      // 不能只更新连载中动漫，因为有些未播放，后面需要更新后才会变成连载
      if (anime.playStatus.contains("完结") ||
          anime.animeUrl.contains("douban") ||
          anime.animeUrl
              .contains("bangumi.tv") || // 次元城动漫详细链接包含bangumi，因此要额外添加.tv避免过滤次元城
          anime.animeUrl.isEmpty) {
        continue;
      }
      needUpdateAnimes.add(anime);
    }
    return needUpdateAnimes;
  }

  /// 查询某个搜索源下的动漫数量
  static Future<int> getAnimesCntBySourceKeyword(String sourceKeyword) async {
    List<Map<String, Object?>> list = await db.rawQuery('''
    select count(anime_id) cnt
    from anime
    where anime_url like '%$sourceKeyword%';
    ''');
    return list[0]['cnt'] as int;
  }

  /// 查询某个搜索源下的所有动漫
  static Future<List<Anime>> getAnimesBySourceKeyword(
      {required String sourceKeyword, required PageParams pageParams}) async {
    List<Anime> animes = [];

    // id用于表示动漫，name和cover用于显示，url用于确定是否已迁移
    List<Map<String, Object?>> list = await db.rawQuery('''
    select anime_id, anime_name, anime_cover_url, anime_url
    from anime
    where anime_url like '$sourceKeyword'
    order by anime_id desc limit ${pageParams.pageSize} offset ${pageParams.getOffset()};
    ''');
    Log.info(
        "分页(limit ${pageParams.pageSize} offset ${pageParams.getOffset()})查询$sourceKeyword下的动漫");
    for (Map row in list) {
      Anime anime = Anime(
          animeId: row['anime_id'],
          animeName: row['anime_name'],
          animeCoverUrl: row['anime_cover_url'],
          animeUrl: row['anime_url']);
      animes.add(anime);
    }

    return animes;
  }

  /// 查询某个动漫的动漫网址
  static Future<String> getAnimeUrlById(int animeId) async {
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

  /// 找出相同名字的动漫
  static Future<List<Anime>> getDupAnimes() async {
    List<Anime> animes = [];

    // id用于表示动漫，name和cover用于显示，url用于确定是否已迁移
    List<Map<String, Object?>> list = await db.rawQuery('''
    select anime_id
    from anime
    where anime_name in (
        select anime_name
        from anime
        group by anime_name
        having count(anime_name) >= 2
    );
    ''');
    for (Map row in list) {
      // Anime anime = Anime(
      //     animeId: row['anime_id'],
      //     animeName: row['anime_name'],
      //     animeCoverUrl: row['anime_cover_url'],
      //     animeUrl: row['anime_url']);

      // 最好获取到观看进度，方便用户去重
      Anime anime = await SqliteUtil.getAnimeByAnimeId(row['anime_id']);
      animes.add(anime);
    }

    return animes;
  }

  static Future<bool> deleteAnimeByAnimeId(int animeId) async {
    Log.info("sql: deleteAnimeByAnimeId(animeId=$animeId)");
    // 由于history表引用了anime表的anime_id，首先删除历史记录，再删除动漫
    await db.rawDelete('''
      delete from history
      where anime_id = $animeId;
      ''');
    await db.rawDelete('''
      delete from anime
      where anime_id = $animeId;
      ''');

    // 删除相关笔记、图片
    // 先根据animeId找到所有笔记，然后根据笔记id找到图片，删除图片后再删除笔记
    await db.rawDelete('''
      delete from image
      where note_id in (
        select note_id from episode_note
        where anime_id = $animeId
      );
      ''');
    await db.rawDelete('''
      delete from episode_note
      where anime_id = $animeId;
      ''');
    // 删除相关更新记录
    await db.rawDelete('''
      delete from update_record
      where anime_id = $animeId;
      ''');

    // 删除所关联的标签(不需要await等待)
    db.rawDelete('''
      delete from anime_label
      where anime_id = $animeId;
      ''');

    return true;
  }

  static Future<bool> existAnimeName(String animeName) async {
    // 使用query而不是rawQuery，不用担心单引号问题
    return (await db
            .query("anime", where: "anime_name = ?", whereArgs: [animeName]))
        .isNotEmpty;
  }
}
