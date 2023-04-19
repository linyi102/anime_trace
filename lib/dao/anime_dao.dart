import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/utils/escape_util.dart';
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

  /// 添加动漫
  static Future<int> insertAnime(Anime anime) async {
    Log.info("sql: insertAnime(anime:$anime)");

    String datetime = DateTime.now().toString();
    return db.insert('anime', {
      'anime_name': anime.animeName,
      'anime_episode_cnt': anime.animeEpisodeCnt,
      'anime_desc': anime.animeDesc,
      'tag_name': anime.tagName,
      'last_mode_tag_time': datetime,
      'anime_cover_url': anime.animeCoverUrl,
      'premiere_time': anime.premiereTime,
      'name_another': anime.nameAnother,
      'name_ori': anime.nameOri,
      'author_ori': anime.authorOri,
      'area': anime.area,
      'play_status': anime.playStatus,
      'production_company': anime.productionCompany,
      'official_site': anime.officialSite,
      'category': anime.category,
      'anime_url': anime.animeUrl,
      'review_number': anime.reviewNumber,
    });
  }

  /// 搜索动漫
  static Future<List<Anime>> getAnimesBySearch(String keyword) async {
    Log.info("sql: getAnimesBySearch");
    keyword = EscapeUtil.escapeStr(keyword);

    var list = await db.rawQuery('''
      select * from anime
      where anime_name like '%$keyword%' or name_another like '%$keyword%';
      ''');

    List<Anime> res = [];
    for (var element in list) {
      int animeId = element['anime_id'] as int;
      int reviewNumber = element['review_number'] as int;
      int checkedEpisodeCnt = await SqliteUtil.getCheckedEpisodeCntByAnimeId(
          animeId,
          reviewNumber: reviewNumber);
      Anime anime = Anime(
        animeId: animeId,
        // 进入详细页面后需要该id
        animeName: element['anime_name'] as String? ?? "",
        nameAnother: element['name_another'] as String? ?? "",
        animeEpisodeCnt: element['anime_episode_cnt'] as int? ?? 0,
        checkedEpisodeCnt: checkedEpisodeCnt,
        animeCoverUrl: element['anime_cover_url'] as String? ?? "",
        reviewNumber: reviewNumber,
      );
      res.add(anime);
    }
    return res;
  }

  /// 迁移动漫、全局更新动漫
  static Future<int> updateAnime(Anime oldAnime, Anime newAnime,
      {bool updateCover = false,
      bool updateName = true,
      bool updateInfo = true}) async {
    Log.info("sql: updateAnime");
    String datetime = DateTime.now().toString();
    Log.info("oldAnime=$oldAnime, newAnime=$newAnime");

    // 如果标签不一样，需要更新最后修改标签的时间
    if (newAnime.tagName.isNotEmpty && oldAnime.tagName != newAnime.tagName) {
      await db.rawUpdate('''
        update anime
        set last_mode_tag_time = '$datetime' -- 更新最后修改标签的时间
        where anime_id = ${oldAnime.animeId};
      ''');
      Log.info("last_mode_tag_time: $datetime");
    }
    // 改基础信息
    // 如果爬取的集数量大于旧数量，则改变，否则不变(旧的大集数赋值上去)
    if (newAnime.animeEpisodeCnt < oldAnime.animeEpisodeCnt) {
      newAnime.animeEpisodeCnt = oldAnime.animeEpisodeCnt;
    }

    if (!updateName) {
      newAnime.animeName = oldAnime.animeName;
    }

    // 如果新动漫某些属性为空字符串，则把旧的赋值上去
    if (newAnime.animeDesc.isEmpty) newAnime.animeDesc = oldAnime.animeDesc;
    if (newAnime.tagName.isEmpty) newAnime.tagName = oldAnime.tagName;

    // 如果没有新封面，或者不迁移封面，就使用旧的
    if (newAnime.animeCoverUrl.isEmpty || !updateCover) {
      newAnime.animeCoverUrl = oldAnime.animeCoverUrl;
    }
    // 如果新信息为空，或者不迁移信息，就使用旧的
    if (newAnime.premiereTime.isEmpty | !updateInfo) {
      newAnime.premiereTime = oldAnime.premiereTime;
    }
    if (newAnime.nameAnother.isEmpty | !updateInfo) {
      newAnime.nameAnother = oldAnime.nameAnother;
    }
    if (newAnime.nameOri.isEmpty | !updateInfo) {
      newAnime.nameOri = oldAnime.nameOri;
    }
    if (newAnime.authorOri.isEmpty | !updateInfo) {
      newAnime.authorOri = oldAnime.authorOri;
    }
    if (newAnime.area.isEmpty | !updateInfo) newAnime.area = oldAnime.area;
    if (newAnime.playStatus.isEmpty | !updateInfo) {
      newAnime.playStatus = oldAnime.playStatus;
    }
    if (newAnime.productionCompany.isEmpty | !updateInfo) {
      newAnime.productionCompany = oldAnime.productionCompany;
    }
    if (newAnime.officialSite.isEmpty | !updateInfo) {
      newAnime.officialSite = oldAnime.officialSite;
    }
    if (newAnime.category.isEmpty | !updateInfo) {
      newAnime.category = oldAnime.category;
    }

    if (newAnime.animeUrl.isEmpty) newAnime.animeUrl = oldAnime.animeUrl;

    if (newAnime.reviewNumber == 0) {
      if (oldAnime.reviewNumber <= 0) oldAnime.reviewNumber = 1;
      newAnime.reviewNumber = oldAnime.reviewNumber;
    }

    return db.update(
        'anime',
        {
          'anime_name': newAnime.animeName,
          'anime_desc': newAnime.animeDesc,
          'tag_name': newAnime.tagName,
          'anime_cover_url': newAnime.animeCoverUrl,
          'anime_episode_cnt': newAnime.animeEpisodeCnt,
          'premiere_time': newAnime.premiereTime,
          'name_another': newAnime.nameAnother,
          'name_ori': newAnime.nameOri,
          'author_ori': newAnime.authorOri,
          'area': newAnime.area,
          'play_status': newAnime.playStatus,
          'production_company': newAnime.productionCompany,
          'official_site': newAnime.officialSite,
          'category': newAnime.category,
          'anime_url': newAnime.animeUrl,
          'review_number': newAnime.reviewNumber
        },
        where: 'anime_id = ?',
        whereArgs: [oldAnime.animeId]);
  }

  static void updateReviewNumber(int animeId, int value) {
    db.rawUpdate('''
    update anime
    set review_number = $value
    where anime_id = $animeId;
    ''');
  }

  static void updateArea(int animeId, String value) {
    db.rawUpdate('''
    update anime
    set area = '$value'
    where anime_id = $animeId;
    ''');
  }

  static void updateCategory(int animeId, String value) {
    db.rawUpdate('''
    update anime
    set category = '$value'
    where anime_id = $animeId;
    ''');
  }

  static void updatePremiereTime(int animeId, String value) {
    db.rawUpdate('''
    update anime
    set premiere_time = '$value'
    where anime_id = $animeId;
    ''');
  }

  static void updateAnimeRate(int animeId, int rate) async {
    Log.info("sql: updateAnimeRate(animeId=$animeId, rate=$rate)");
    db.rawUpdate('''
    update anime
    set rate = $rate
    where anime_id = $animeId;
    ''');
  }

  static void updateAnimeUrl(int animeId, String animeUrl) async {
    Log.info("sql: updateAnimeUrl");
    animeUrl = EscapeUtil.escapeStr(animeUrl);
    db.rawUpdate('''
    update anime
    set anime_url = '$animeUrl'
    where anime_id = $animeId;
    ''');
  }

  static Future<void> updateAnimeCoverUrl(
      int animeId, String animeCoverUrl) async {
    Log.info("sql: updateAnimeCoverUrl");
    animeCoverUrl = EscapeUtil.escapeStr(animeCoverUrl);
    db.rawUpdate('''
    update anime
    set anime_cover_url = '$animeCoverUrl'
    where anime_id = $animeId;
    ''');
  }

  static void updateAnimeNameByAnimeId(int animeId, String newAnimeName) async {
    Log.info("sql: updateAnimeNameByAnimeId");
    newAnimeName = EscapeUtil.escapeStr(newAnimeName);
    db.rawUpdate('''
    update anime
    set anime_name = '$newAnimeName'
    where anime_id = $animeId;
    ''');
  }

  static void updateAnimeNameAnotherByAnimeId(
      int animeId, String newNameAnother) async {
    Log.info("sql: updateAnimeNameAnotherByAnimeId");
    newNameAnother = EscapeUtil.escapeStr(newNameAnother);
    db.rawUpdate('''
    update anime
    set name_another = '$newNameAnother'
    where anime_id = $animeId;
    ''');
  }

  static void updateAnimeDescByAnimeId(int animeId, String newDesc) async {
    Log.info("sql: updateAnimeDescByAnimeId");
    newDesc = EscapeUtil.escapeStr(newDesc);
    db.rawUpdate('''
    update anime
    set anime_desc = '$newDesc'
    where anime_id = $animeId;
    ''');
  }

  static void updateAnimePlayStatusByAnimeId(
      int animeId, String newPlayStatus) async {
    Log.info("sql: updateAnimePlayStatusByAnimeId");
    db.rawUpdate('''
    update anime
    set play_status = '$newPlayStatus'
    where anime_id = $animeId;
    ''');
  }

  static void updateTagByAnimeId(int animeId, String newTagName) async {
    Log.info("sql: updateTagNameByAnimeId");
    // 同时修改最后一次修改标签的时间
    db.rawUpdate('''
    update anime
    set tag_name = '$newTagName', last_mode_tag_time = '${DateTime.now().toString()}'
    where anime_id = $animeId;
    ''');
  }

  static void updateDescByAnimeId(int animeId, String desc) async {
    Log.info("sql: updateDescByAnimeId");
    db.rawUpdate('''
    update anime
    set anime_desc = '$desc'
    where anime_id = $animeId;
    ''');
  }

  static Future<bool> updateEpisodeCntByAnimeId(
      int animeId, int episodeCnt) async {
    Log.info("sql: updateEpisodeCntByAnimeId");

    return await db.rawUpdate('''
      update anime
      set anime_episode_cnt = $episodeCnt
      where anime_id = $animeId;
      ''') > 0;
  }
}
