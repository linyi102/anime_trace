import 'package:animetrace/dao/anime_label_dao.dart';
import 'package:animetrace/dao/anime_series_dao.dart';
import 'package:animetrace/dao/key_value_dao.dart';
import 'package:animetrace/models/anime_episode_info.dart';
import 'package:animetrace/models/enum/anime_area.dart';
import 'package:animetrace/models/enum/anime_category.dart';
import 'package:animetrace/models/enum/play_status.dart';
import 'package:animetrace/models/params/page_params.dart';
import 'package:animetrace/pages/local_search/models/local_select_filter.dart';
import 'package:animetrace/utils/climb/climb_anime_util.dart';
import 'package:animetrace/utils/escape_util.dart';
import 'package:animetrace/utils/global_data.dart';
import 'package:animetrace/utils/sqlite_util.dart';
import 'package:animetrace/utils/log.dart';

import '../models/anime.dart';

class AnimeDao {
  static final db = SqliteUtil.database;

  static const String table = 'anime';
  static const String columnId = 'anime_id';
  static const String columnUrl = 'anime_url';
  static const String columnSource = 'anime_source';
  static const String columnBgmSubjectId = 'bgm_subject_id';
  static const String columnRate = 'rate';

  static Future<List<Anime>> getAnimes({
    List<String>? columns,
    PageParams? page,
  }) async {
    Log.info("sql: getAnimes");

    final rows = await db.query(
      table,
      columns: null,
      limit: page?.pageSize,
      offset: page?.getOffset(),
    );

    List<Anime> res = [];
    for (var row in rows) {
      res.add(await row2Bean(row));
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
  static Future<List<Anime>> getAllNeedUpdateAnimes({
    bool includeEmptyUrl = false,
  }) async {
    List<Anime> animes = await getAnimes();
    List<Anime> needUpdateAnimes = [];

    for (var anime in animes) {
      // 跳过完结动漫、豆瓣、自定义动漫(也就是没有动漫地址)
      // 不能只更新连载中动漫，因为有些未播放，后面需要更新后才会变成连载
      if (anime.playStatus.contains("完结") ||
          anime.animeUrl.contains("douban")) {
        continue;
      }
      if (!includeEmptyUrl && anime.animeUrl.isEmpty) {
        continue;
      }

      needUpdateAnimes.add(anime);
    }
    return needUpdateAnimes;
  }

  /// 查询某个搜索源下的动漫数量
  static Future<int> getAnimesCntInSource(int sourceId) async {
    List<Map<String, Object?>> list = await db.rawQuery('''
      select count(anime_id) cnt
      from anime
      where $columnSource = $sourceId;
    ''');
    return list[0]['cnt'] as int;
  }

  /// 查询某个搜索源下的所有动漫
  static Future<List<Anime>> getAnimesInSource(
      {required int sourceId, PageParams? pageParams}) async {
    List<Anime> animes = [];

    // id用于表示动漫，name和cover用于显示，url用于确定是否已迁移
    List<Map<String, Object?>> list = await db.rawQuery('''
      select anime_id, anime_name, name_another, anime_cover_url, anime_url, play_status, premiere_time
      from anime
      where $columnSource = $sourceId
      order by anime_id desc ${pageParams != null ? 'limit ${pageParams.pageSize} offset ${pageParams.getOffset()}' : ''};
    ''');
    if (pageParams != null) {
      Log.info(
          "分页(limit ${pageParams.pageSize} offset ${pageParams.getOffset()})查询$sourceId下的动漫");
    }
    for (Map row in list) {
      Anime anime = Anime(
        animeId: row['anime_id'],
        animeName: row['anime_name'],
        nameAnother: row['name_another'] as String? ?? '',
        animeCoverUrl: row['anime_cover_url'],
        animeUrl: row['anime_url'],
        playStatus: row['play_status'] as String? ?? '',
        premiereTime: row['premiere_time'] as String? ?? '',
      );
      animes.add(anime);
    }

    return animes;
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
    // 从系列中删除
    db.rawDelete('''
      delete from anime_series
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
    final website = ClimbAnimeUtil.getClimbWebsiteByAnimeUrl(anime.animeUrl);

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
      columnSource: website?.id,
    });
  }

  /// 根据关键字搜索动漫
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
        premiereTime: element['premiere_time'] as String? ?? '',
        reviewNumber: reviewNumber,
      );
      res.add(anime);
    }
    res.sort((a, b) => -a.premiereTime.compareTo(b.premiereTime));
    return res;
  }

  static Future<List<Anime>> complexSearch(LocalSelectFilter filter) async {
    List<Anime> result = [];

    final keywordSql = filter.keyword == null || filter.keyword!.isEmpty
        ? ''
        : 'anime_name like "%${filter.keyword}%" or name_another like "%${filter.keyword}%"';
    final checklistSql = filter.checklist == null || filter.checklist!.isEmpty
        ? ''
        : 'tag_name = "${filter.checklist}"';
    final areaSql = filter.area == null
        ? ''
        : 'area = "${filter.area == AnimeArea.unknown ? '' : filter.area!.label}"';
    final categorySql = filter.category == null
        ? ''
        : 'category = "${filter.category == AnimeCategory.unknown ? '' : filter.category!.label}"';
    final airDateSql = filter.airDate == null
        ? ''
        : 'premiere_time like "%${filter.airDate}%"';
    final playStatusSql = filter.playStatus == null
        ? ''
        : PlayStatus.toWhereSql(filter.playStatus!);
    final sourceSql = filter.source == null
        ? ''
        : () {
            if (filter.source?.id == customSourceId) {
              return '$columnSource is null';
            } else {
              return '$columnSource = ${filter.source?.id}';
            }
          }();
    // rate为null表示不根据评分搜索
    final rateSql = filter.rate == null ? '' : 'rate = ${filter.rate}';
    final sqls = [
      keywordSql,
      checklistSql,
      areaSql,
      categorySql,
      airDateSql,
      playStatusSql,
      rateSql,
      sourceSql,
    ].where((sql) => sql.isNotEmpty);

    if (sqls.isEmpty) {
      if (filter.labels.isEmpty) return [];
      result = await AnimeLabelDao.getAnimesByLabelIds(
          filter.labels.map((e) => e.id).toList());
    } else {
      // 拼接时为每个查询sql添加()，避免因为or导致优先级错误
      final whereSql = sqls.map((e) => '($e)').join(' and ');
      final list = await db.rawQuery('''
        select * from $table
        where $whereSql
      ''');
      final List<Anime> animes = [];

      for (final row in list) {
        int animeId = row['anime_id'] as int;
        int reviewNumber = row['review_number'] as int;
        int checkedEpisodeCnt = await SqliteUtil.getCheckedEpisodeCntByAnimeId(
            animeId,
            reviewNumber: reviewNumber);
        Anime anime = Anime(
          animeId: animeId,
          // 进入详细页面后需要该id
          animeName: row['anime_name'] as String? ?? "",
          nameAnother: row['name_another'] as String? ?? "",
          animeEpisodeCnt: row['anime_episode_cnt'] as int? ?? 0,
          checkedEpisodeCnt: checkedEpisodeCnt,
          animeCoverUrl: row['anime_cover_url'] as String? ?? "",
          premiereTime: row['premiere_time'] as String? ?? '',
          reviewNumber: reviewNumber,
        );
        animes.add(anime);
      }
      if (filter.labels.isEmpty) {
        result = animes;
      } else {
        // 从标签查询的动漫列表中过滤动漫
        final labelAnimes = await AnimeLabelDao.getAnimesByLabelIds(
            filter.labels.map((e) => e.id).toList());
        for (final labelAnime in labelAnimes) {
          if (animes
                  .indexWhere((anime) => anime.animeId == labelAnime.animeId) >=
              0) {
            result.add(labelAnime);
          }
        }
      }
    }

    // 按首播时间降序排列，最新的在最前面
    result.sort((a, b) => -a.premiereTime.compareTo(b.premiereTime));
    return result;
  }

  /// 迁移动漫、全局更新动漫
  static Future<int> updateAnime(Anime oldAnime, Anime newAnime,
      {bool updateCover = false,
      bool updateName = true,
      bool updateInfo = true,
      bool updateAnimeUrl = true}) async {
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
    if (newAnime.animeUrl.isEmpty | !updateAnimeUrl) {
      newAnime.animeUrl = oldAnime.animeUrl;
    }
    final website = ClimbAnimeUtil.getClimbWebsiteByAnimeUrl(newAnime.animeUrl);

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
          'review_number': newAnime.reviewNumber,
          columnSource: website?.id,
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

  static Future<void> updateAnimeUrl(int animeId, String animeUrl) async {
    Log.info("sql: updateAnimeUrl");
    animeUrl = EscapeUtil.escapeStr(animeUrl);
    final website = ClimbAnimeUtil.getClimbWebsiteByAnimeUrl(animeUrl);

    await db.update(
      table,
      {
        columnUrl: animeUrl,
        columnSource: website?.id,
      },
      where: '$columnId = ?',
      whereArgs: [animeId],
    );
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

  static Future<bool> updateEpisodeInfoByAnimeId(
      int animeId, AnimeEpisodeInfo episodeInfo) async {
    Log.info("sql: updateEpisodeCntAndStartNumberByAnimeId");

    return await db.rawUpdate('''
      update anime
      set anime_episode_cnt = ${episodeInfo.totalCnt}, episode_start_number = ${episodeInfo.startNumber}, cal_episode_number_from_one = ${episodeInfo.calNumberFromOne ? 1 : 0}
      where anime_id = $animeId;
      ''') > 0;
  }

  /// 最早收藏动漫
  static Future<Anime?> getFirstCollectedAnime() async {
    Log.info("sql: getFirstCollectedAnime");

    var cols = await db.rawQuery('''
      select anime_id from anime order by anime_id limit 1;
    ''');
    // 还没有动漫
    if (cols.isEmpty) return null;

    int id = cols.first['anime_id'] as int;
    return SqliteUtil.getAnimeByAnimeId(id);
  }

  /// 最早开播动漫
  static Future<Anime?> getFirstPremieredAnime() async {
    Log.info("sql: getFirstPremieredAnime");

    var cols = await db.rawQuery('''
      select * from anime order by case when length(premiere_time) = 0 then '9' else premiere_time end limit 1;
    ''');
    if (cols.isEmpty) return null;
    return SqliteUtil.getAnimeByAnimeId(cols.first['anime_id'] as int);
  }

  /// 历史表中回顾数最大的动漫
  static Future<Map<String, dynamic>?> getMaxReviewCntAnime() async {
    Log.info("sql: getMaxReviewCntAnime");

    var cols = await db.rawQuery('''
      select anime_id, review_number from history order by review_number desc limit 1;
    ''');
    if (cols.isEmpty) return null;

    var col = cols.first;
    var anime = await SqliteUtil.getAnimeByAnimeId(col['anime_id'] as int);
    return {
      'anime': anime,
      'maxReviewCnt': col['review_number'],
    };
  }

  /// 收藏的动漫数量
  static Future<int> getTotal() async {
    Log.info('sql: anime getTotal');

    var cols = await db.rawQuery('''
      select count(anime_id) total from anime;
    ''');
    return cols.first['total'] as int;
  }

  /// 前n年今天开播的动漫
  static Future<List<Anime>> getAnimesNYearAgoToday() async {
    Log.info('sql: getAnimesNYearAgoToday');

    var now = DateTime.now();
    var month = now.toString().substring(5, 7);
    var day = now.toString().substring(8, 10);
    var rows = await db.rawQuery('''
      select * from anime where premiere_time like '%-$month-$day';
    ''');
    List<Anime> animes = [];
    for (var row in rows) {
      animes.add(await row2Bean(row, queryCheckedEpisodeCnt: false));
    }
    return animes;
  }

  static Future<Anime> row2Bean(
    Map<String, Object?> row, {
    bool queryCheckedEpisodeCnt = false,
    bool queryHasJoinedSeries = false,
  }) async {
    final anime = Anime(
      animeId: row['anime_id'] as int,
      animeName: row['anime_name'] as String? ?? '',
      animeEpisodeCnt: row['anime_episode_cnt'] as int? ?? 0,
      episodeStartNumber: row['episode_start_number'] as int? ?? 1,
      calEpisodeNumberFromOne:
          int2Bool(row['cal_episode_number_from_one'] as int?),
      animeDesc: row['anime_desc'] as String? ?? "",
      animeCoverUrl: row['anime_cover_url'] as String? ?? "",
      tagName: row['tag_name'] as String? ?? '未知',
      reviewNumber: row['review_number'] as int? ?? 0,
      premiereTime: row['premiere_time'] as String? ?? "",
      nameOri: row['name_ori'] as String? ?? "",
      nameAnother: row['name_another'] as String? ?? "",
      authorOri: row['author_ori'] as String? ?? "",
      area: row['area'] as String? ?? "",
      playStatus: row['play_status'] as String? ?? "",
      productionCompany: row['production_company'] as String? ?? "",
      officialSite: row['official_site'] as String? ?? "",
      category: row['category'] as String? ?? "",
      animeUrl: row['anime_url'] as String? ?? "",
      rate: row['rate'] as int? ?? 0,
    );

    if (queryCheckedEpisodeCnt) {
      int checkedEpisodeCnt = await SqliteUtil.getCheckedEpisodeCntByAnimeId(
          anime.animeId,
          reviewNumber: anime.reviewNumber);
      anime.checkedEpisodeCnt = checkedEpisodeCnt;
    }

    if (queryHasJoinedSeries) {
      anime.hasJoinedSeries =
          (await AnimeSeriesDao.getSeriesIdListByAnimeId(anime.animeId))
              .isNotEmpty;
    }

    _restoreEscapeAnime(anime);
    return anime;
  }

  /// int转bool
  static bool int2Bool(int? val) {
    return val == null || val == 0 ? false : true;
  }

  /// 转义后，单个单引号会变为两个单引号存放在数据库，查询的时候得到的是两个单引号，因此也需要恢复
  static Anime _restoreEscapeAnime(Anime anime) {
    anime.animeName = EscapeUtil.restoreEscapeStr(anime.animeName);
    anime.animeDesc = EscapeUtil.restoreEscapeStr(anime.animeDesc);
    anime.tagName = EscapeUtil.restoreEscapeStr(anime.tagName);
    anime.nameAnother = EscapeUtil.restoreEscapeStr(anime.nameAnother);
    anime.nameOri = EscapeUtil.restoreEscapeStr(anime.nameOri);
    return anime;
  }

  /// 新增搜索源列
  static Future<void> addColumnSourceForAnime() async {
    Future<void> updateAllAnimeSource() async {
      int pageSize = 50;
      for (int pageIndex = 0;; pageIndex++) {
        final rows = await db.query(
          table,
          columns: [columnId, columnUrl],
          offset: pageIndex * pageSize,
          limit: pageSize,
        );
        if (rows.isEmpty) break;

        for (final row in rows) {
          updateSource(row[columnId] as int?, row[columnUrl] as String?);
        }
      }
    }

    await SqliteUtil.addColumnName(
      tableName: table,
      columnName: columnSource,
      columnType: 'INTEGER',
      logName: 'addColumnSourceForAnime',
      whenAddSuccess: updateAllAnimeSource,
    );
  }

  static Future<void> updateSource(int? animeId, String? url) async {
    if (animeId == null || url == null) return;
    final website = ClimbAnimeUtil.getClimbWebsiteByAnimeUrl(url);

    await db.update(
      table,
      {columnSource: website?.id},
      where: '$columnId = ?',
      whereArgs: [animeId],
    );
  }

  /// 新增Bangumi SubjectId列
  static Future<void> addColumnBgmSubjectId() async {
    await SqliteUtil.addColumnName(
      tableName: table,
      columnName: columnBgmSubjectId,
      columnType: 'TEXT',
      logName: 'addColumnBgmSubjectId',
    );
  }

  static Future<String> getBgmSubjectId(int animeId) async {
    final rows = await db.query(
      table,
      columns: [columnBgmSubjectId],
      where: '$columnId = ?',
      whereArgs: [animeId],
    );
    return rows.first[columnBgmSubjectId] as String? ?? '';
  }

  static Future<bool> setBgmSubjectId(int animeId, String subjectId) async {
    final successCnt = await db.update(
      table,
      {
        columnBgmSubjectId: subjectId,
      },
      where: '$columnId = ?',
      whereArgs: [animeId],
    );
    return successCnt > 0;
  }

  /// 支持半星
  static Future<void> doubleRateToSupportHalfStar() async {
    final supportHalfStar =
        await KeyValueDao.getBool('supportHalfStar') ?? false;
    if (supportHalfStar) return;

    logger.info('[table $table] double rate');
    await db.rawUpdate('''
      UPDATE $table SET $columnRate = $columnRate * 2
      WHERE $columnRate IS NOT NULL and $columnRate != 0;
    ''');
    await KeyValueDao.setBool('supportHalfStar', true);
  }
}
