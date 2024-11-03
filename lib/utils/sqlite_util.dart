import 'dart:io';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/dao/anime_label_dao.dart';
import 'package:flutter_test_future/dao/anime_series_dao.dart';
import 'package:flutter_test_future/dao/episode_desc_dao.dart';
import 'package:flutter_test_future/dao/key_value_dao.dart';
import 'package:flutter_test_future/dao/label_dao.dart';
import 'package:flutter_test_future/dao/series_dao.dart';
import 'package:flutter_test_future/models/params/anime_sort_cond.dart';
import 'package:flutter_test_future/utils/episode.dart';
import 'package:flutter_test_future/utils/escape_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/episode.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SqliteUtil {
  // 单例模式
  static SqliteUtil? _instance;

  SqliteUtil._();

  static Future<SqliteUtil> getInstance() async {
    database = await _initDatabase();
    return _instance ??= SqliteUtil._();
  }

  static const sqlFileName = 'mydb.db';
  static late Database database;
  static late String dbPath;

  static Future<bool> ensureDBTable() async {
    // 大多都要用await，才返回true，否则会提前返回，导致表还未创建等错误
    await ImageUtil.getInstance();
    await SqliteUtil.getInstance();
    // 先创建表，再添加列
    await SqliteUtil.createTableEpisodeNote();
    await SqliteUtil.createTableImage();

    await SqliteUtil.addColumnReviewNumberToHistoryAndNote(); // 添加回顾号列
    await SqliteUtil.addColumnInfoToAnime(); // 为动漫表添加列

    // 创建动漫更新表
    await SqliteUtil.createTableUpdateRecord();
    // 为动漫表增加评分列
    await SqliteUtil.addColumnRateToAnime();
    // 为动漫表增加起始集数列
    await SqliteUtil.addColumnEpisodeStartNumberToAnime();
    // 为动漫表增加集号是否从第1集计算
    await SqliteUtil.addColumnCalEpisodeNumberFromOneToAnime();
    // 为动漫表增加搜索源
    await AnimeDao.addColumnSourceForAnime();
    // 为笔记增加创建时间和修改时间列，主要用于评分时显示
    await SqliteUtil.addColumnTwoTimeToEpisodeNote();
    // 为图片表增加顺序列，支持自定义排序
    await SqliteUtil.addColumnOrderIdxToImage();

    // 创建标签表、动漫标签表、集描述表
    await LabelDao.createTable();
    await AnimeLabelDao.createTable();
    await EpisodeDescDao.createTable();
    // 创建系列表、动漫系列表
    await SeriesDao.createTable();
    await AnimeSeriesDao.createTable();
    // 创建键值对表
    await KeyValueDao.createTable();
    return true;
  }

  static _initDatabase() async {
    if (Platform.isAndroid) {
      // dbPath = "${(await getExternalStorageDirectory())!.path}/$sqlFileName";
      dbPath = "${(await getApplicationSupportDirectory()).path}/$sqlFileName";
      Log.info("👉Android: path=$dbPath");
      // await deleteDatabase(dbPath); // 删除Android数据库
      return await openDatabase(
        dbPath,
        onCreate: (Database db, int version) {
          Future(() {
            _createInitTable(db); // 只会在数据库创建时才会创建表，记得传入的是db，而不是databse
          }).then((value) async {
            await _insertInitData(db); // await确保加载数据后再执行后面的语句
          });
        },
        version: 1, // onCreate must be null if no version is specified
      );
    } else if (Platform.isWindows) {
      dbPath =
          "${(await getApplicationSupportDirectory()).path}/$sqlFileName"; // 使用
      // await deleteDatabase(dbPath); // 删除桌面端数据库，然而并不能删除
      Log.info("👉Windows: path=$dbPath");
      var databaseFactory = databaseFactoryFfi;
      return await databaseFactory.openDatabase(dbPath,
          // onCreate、version都封装到了options中
          options: OpenDatabaseOptions(
            onCreate: (Database db, int version) {
              Future(() {
                _createInitTable(db);
              }).then((value) async {
                await _insertInitData(db);
              });
            },
            version: 1,
          ));
    } else {
      throw ("未适配平台：${Platform.operatingSystem}");
    }
  }

  static void _createInitTable(Database db) async {
    await db.execute('''
      CREATE TABLE tag (
          -- tag_id    INTEGER PRIMARY KEY AUTOINCREMENT,
          tag_name  TEXT    PRIMARY KEY NOT NULL,
          tag_order INTEGER
      );
      ''');
    await db.execute('''
      CREATE TABLE anime (
          anime_id            INTEGER PRIMARY KEY AUTOINCREMENT,
          anime_name          TEXT    NOT NULL,
          anime_episode_cnt   INTEGER NOT NULL,
          anime_desc          TEXT, -- 描述
          tag_name            TEXT,
          last_mode_tag_time  TEXT, -- 最后一次修改标签的时间，可以实现新移动的在列表上面
          FOREIGN KEY (
              tag_name
          )
          REFERENCES tag (tag_name)
      );
      ''');
    await db.execute('''
      CREATE TABLE history (
          history_id     INTEGER PRIMARY KEY AUTOINCREMENT,
          date           TEXT,
          anime_id       INTEGER NOT NULL,
          episode_number INTEGER NOT NULL,
          FOREIGN KEY (
              anime_id
          )
          REFERENCES anime (anime_id)
      );
      ''');
    await db.execute('''
      CREATE INDEX index_anime_name ON anime (anime_name);
      '''); // 不知道为啥放在创建history语句前就会导致history表还没创建就插入数据，从而导致错误
    // 新增
    await db.execute('''
      CREATE INDEX index_date ON history (date);
      ''');
  }

  static Future<void> _insertInitData(Database db) async {
    await db.rawInsert('''
      insert into tag(tag_name, tag_order)
      -- values('拾'), ('途'), ('终'), ('搁'), ('弃');
      values('收集', 0), ('旅途', 1), ('终点', 2), ('搁置', 3), ('放弃', 4);
    ''');
  }

  static Future<void> addColumnInfoToAnime() async {
    Map<String, String> columns = {};
    columns['anime_cover_url'] = 'TEXT'; // 封面链接
    columns['premiere_time'] = 'TEXT'; // 首播时间
    columns['name_another'] = 'TEXT'; // 其他名称
    columns['name_ori'] = 'TEXT'; // 原版名称
    columns['author_ori'] = 'TEXT'; // 原版作者
    columns['area'] = 'TEXT'; // 地区
    columns['play_status'] = 'TEXT'; // 播放状态
    columns['category'] = 'TEXT'; // 动漫类型
    columns['production_company'] = 'TEXT'; // 制作公司
    columns['official_site'] = 'TEXT'; // 官方网站
    columns['anime_url'] = 'TEXT'; // 动漫网址
    columns['review_number'] = 'INTEGER'; // 回顾号
    columns.forEach((key, value) async {
      var list = await database.rawQuery('''
        select * from sqlite_master where name = 'anime' and sql like '%$key%';
      ''');
      if (list.isEmpty) {
        await database.execute('''
          alter table anime
          add column $key $value;
        ''').then((value) async {
          if (key == 'review_number') {
            Log.info("修改回顾号为1");
            // 新增的回顾号列才会修改NULL→1，之后插入新动漫默认回顾号为1
            await database.rawUpdate('''
              update anime
              set review_number = 1
              where review_number is NULL;
            ''');
          }
        });
      }
    });
  }

  // 为历史表和笔记表添加列：回顾号
  // 并将NULL改为1
  static Future<void> addColumnReviewNumberToHistoryAndNote() async {
    var list = await database.rawQuery('''
    select * from sqlite_master where name = 'history' and sql like '%review_number%';
    ''');
    // 没有列时添加
    if (list.isEmpty) {
      Log.info("sql: addColumnReviewNumberToHistoryAndNote");
      await database.execute('''
      alter table history
      add column review_number INTEGER;
      ''');

      // 新增列才会修改NULL→1，之后就不修改了
      await database.rawUpdate('''
      update history
      set review_number = 1
      where review_number is NULL;
      ''');
    }
    list = await database.rawQuery('''
    select * from sqlite_master where name = 'episode_note' and sql like '%review_number%';
    ''');
    // 没有列时添加
    if (list.isEmpty) {
      Log.info("sql: addColumnReviewNumberToHistoryAndNote");
      await database.execute('''
      alter table episode_note
      add column review_number INTEGER;
      ''');

      await database.rawUpdate('''
      update episode_note
      set review_number = 1
      where review_number is NULL;
      ''');
    }
  }

  static Future<void> addColumnRateToAnime() async {
    var list = await database.rawQuery('''
    select * from sqlite_master where name = 'anime' and sql like '%rate%';
    ''');
    // 没有列时添加
    if (list.isEmpty) {
      Log.info("sql: addColumnRateToAnime");
      await database.execute('''
      alter table anime
      add column rate INTEGER;
      ''');

      // 新增列才会修改NULL→1，之后就不修改了
      await database.rawUpdate('''
      update anime
      set rate = 0
      where rate is NULL;
      ''');
    }
  }

  static Future<void> addColumnEpisodeStartNumberToAnime() async {
    await addColumnName(
      tableName: 'anime',
      columnName: 'episode_start_number',
      columnType: 'INTEGER',
      logName: 'addColumnEpisodeStartNumberToAnime',
    );
  }

  static Future<void> addColumnCalEpisodeNumberFromOneToAnime() async {
    await addColumnName(
      tableName: 'anime',
      columnName: 'cal_episode_number_from_one',
      columnType: 'INTEGER',
      logName: 'addColumnCalEpisodeNumberFromOneToAnime',
    );
  }

  static Future<void> addColumnName({
    required String tableName,
    required String columnName,
    required String columnType,
    dynamic initialValue,
    String logName = '',
    Function()? whenAddSuccess,
  }) async {
    var list = await database.rawQuery('''
      select * from sqlite_master where name = '$tableName' and sql like '%$columnName%';
      ''');
    if (list.isNotEmpty) return;
    // 没有列时添加
    Log.info("sql: $logName");
    await database.execute('''
      alter table $tableName
      add column $columnName $columnType;
    ''');

    if (initialValue != null) {
      await database.rawUpdate('''
        update $tableName
        set $columnName = $initialValue
        where $columnName is NULL;
      ''');
    }
    whenAddSuccess?.call();
  }

  static Future<void> addColumnTwoTimeToEpisodeNote() async {
    var list = await database.rawQuery('''
    select * from sqlite_master where name = 'episode_note' and sql like '%create_time%';
    ''');
    // 没有列时添加
    if (list.isEmpty) {
      Log.info("sql: addColumnCreateTimeToAnime");
      await database.execute('''
      alter table episode_note
      add column create_time TEXT;
      ''');
    }

    list = await database.rawQuery('''
    select * from sqlite_master where name = 'episode_note' and sql like '%update_time%';
    ''');
    // 没有列时添加
    if (list.isEmpty) {
      Log.info("sql: addColumnUpdateTimeToAnime");
      await database.execute('''
      alter table episode_note
      add column update_time TEXT;
      ''');
    }
  }

  static void insertHistoryItem(
      int animeId, int episodeNumber, String date, int reviewNumber) async {
    Log.info(
        "sql: insertHistoryItem(animeId=$animeId, episodeNumber=$episodeNumber, date=$date, reviewNumber=$reviewNumber)");
    await database.rawInsert('''
    insert into history(date, anime_id, episode_number, review_number)
    values('$date', $animeId, $episodeNumber, $reviewNumber);
    ''');
  }

  static void updateHistoryItem(
      int animeId, int episodeNumber, String date, int reviewNumber) async {
    Log.info("sql: updateHistoryItem");

    await database.rawInsert('''
    update history
    set date = '$date'
    where anime_id = $animeId and episode_number = $episodeNumber and review_number = $reviewNumber;
    ''');
  }

  static void deleteHistoryItemByAnimeIdAndEpisodeNumberAndReviewNumber(
      int animeId, int episodeNumber, int reviewNumber) async {
    Log.info(
        "sql: deleteHistoryItemByAnimeIdAndEpisodeNumberAndReviewNumber(animeId=$animeId, episodeNumber=$episodeNumber)");
    await database.rawDelete('''
      delete from history
      where anime_id = $animeId and episode_number = $episodeNumber and review_number = $reviewNumber;
    ''');
  }

  static void insertTagName(String tagName, int tagOrder) async {
    Log.info("sql: insertTagName");
    await database.rawInsert('''
    insert into tag(tag_name, tag_order)
    values('$tagName', $tagOrder);
    ''');
  }

  static void updateTagName(String oldTagName, String newTagName) async {
    Log.info("sql: updateTagNameByTagId");
    await database.rawUpdate('''
      update tag
      set tag_name = '$newTagName'
      where tag_name = '$oldTagName';
    ''');
    // 更改tag表的tag_name后，还需要更改动漫表中的tag_name列
    await database.rawUpdate('''
      update anime
      set tag_name = '$newTagName'
      where tag_name = '$oldTagName';
    ''');
  }

  static Future<bool> updateTagOrder(List<String> tagNames) async {
    Log.info("sql: updateTagOrder");
    // 错误：把表中标签的名字和list中对应起来即可。这样会导致动漫标签不匹配
    // 应该重建一个order列，从0开始
    for (int i = 0; i < tagNames.length; ++i) {
      await database.rawUpdate('''
      update tag
      set tag_order = $i
      where tag_name = '${tagNames[i]}';
      ''');
    }
    return true;
  }

  static void deleteTagByTagName(String tagName) async {
    Log.info("sql: deleteTagByTagName");
    await database.rawDelete('''
    delete from tag
    where tag_name = '$tagName';
    ''');
  }

  static Future<List<String>> getAllTags() async {
    Log.info("sql: getAllTags");
    var list = await database.rawQuery('''
    select tag_name
    from tag
    order by tag_order
    ''');
    List<String> res = [];
    for (var item in list) {
      res.add(item["tag_name"] as String);
    }
    return res;
  }

  static Future<Anime> getAnimeByAnimeId(int animeId) async {
    Log.info("sql: getAnimeByAnimeId($animeId)");
    var list = await database.rawQuery('''
    select *
    from anime
    where anime_id = $animeId;
    ''');
    if (list.isEmpty) {
      return Anime(animeId: 0, animeName: "", animeEpisodeCnt: 0);
    }
    var row = list[0];
    Anime anime = await AnimeDao.row2Bean(row,
        queryCheckedEpisodeCnt: true, queryHasJoinedSeries: true);
    return anime;
  }

  static Future<Anime> getAnimeByAnimeUrl(Anime anime) async {
    // 不需要根据animeName查找，只根据动漫地址就能知道数据库是否添加了该搜索源下的这个动漫
    // 不能使用的animeName的原因：如果网络搜索fate，可能会找到带有单引号的动漫名，如果按这个动漫名查找，则会出错，需要进行转义。
    // Log.info("sql: getAnimeIdByAnimeNameAndSource()");
    if (anime.animeUrl.isEmpty) {
      anime.animeId = 0;
      anime.tagName = "";
      return anime;
    }
    var list = await database.rawQuery('''
      select *
      from anime
      where anime_url = '${anime.animeUrl}';
    ''');
    // 为空返回旧对象
    if (list.isEmpty) {
      // 传入的对象可能已经在动漫页进入的详细页中被取消收藏了，但目录页显示的旧数据仍然保留着id和tagName等信息
      anime.animeId = 0;
      anime.tagName = "";
      return anime;
    }
    var row = list[0];

    Anime searchedAnime =
        await AnimeDao.row2Bean(row, queryCheckedEpisodeCnt: true);
    return searchedAnime;
  }

  static Future<String> getTagNameByAnimeId(int animeId) async {
    Log.info("sql: getTagNameByAnimeId");
    var list = await database.rawQuery('''
    select tag_name
    from anime
    where anime.anime_id = $animeId;
    ''');
    return list[0]['tag_name'] as String;
  }

  // 获取该动漫的[startEpisodeNumber, endEpisodeNumber]集信息
  static Future<List<Episode>> getEpisodeHistoryByAnimeIdAndRange(
      Anime anime, int startEpisodeNumber, int endEpisodeNumber) async {
    Log.info(
        "sql: getEpisodeHistoryByAnimeIdAndRange(animeId=${anime.animeId}), range=[$startEpisodeNumber, $endEpisodeNumber]");

    var list = await database.rawQuery('''
      select date, episode_number
      from anime inner join history
        on anime.anime_id = ${anime.animeId} and anime.anime_id = history.anime_id and history.review_number = ${anime.reviewNumber}
      where history.episode_number >= $startEpisodeNumber and history.episode_number <= $endEpisodeNumber;
      ''');
    // Log.info("查询结果：$list");
    List<Episode> episodes = [];
    for (int episodeNumber = startEpisodeNumber;
        episodeNumber <= endEpisodeNumber;
        ++episodeNumber) {
      episodes.add(Episode(episodeNumber, anime.reviewNumber,
          startNumber: EpisodeUtil.getFakeEpisodeStartNumber(anime)));
    }
    // 遍历查询结果，每个元素都是一个键值对(列名-值)
    for (var element in list) {
      int episodeNumber = element['episode_number'] as int;
      // 要减去起始编号，才能从下标0开始
      episodes[episodeNumber - startEpisodeNumber].dateTime =
          element['date'] as String;
    }
    return episodes;
  }

  static Future<int> getAnimesCntBytagName(String tagName) async {
    Log.info("sql: getAnimesCntBytagName");
    var list = await database.rawQuery('''
      select count(anime.anime_id) cnt from anime
      where anime.tag_name = '$tagName';
      ''');
    return list[0]["cnt"] as int;
  }

  static Future<int> getCheckedEpisodeCntByAnimeId(int animeId,
      {int reviewNumber = 0}) async {
    // Log.info("getCheckedEpisodeCntByAnimeId(animeId=$animeId)");
    var checkedEpisodeCntList = await database.rawQuery('''
      select count(anime.anime_id) cnt
      from anime inner join history
          on anime.anime_id = $animeId and anime.anime_id = history.anime_id and history.review_number = $reviewNumber;
      ''');
    // Log.info(
    //     "最大回顾号$maxReviewNumber的进度：checkedEpisodeCnt=${checkedEpisodeCntList[0]["cnt"] as int}");
    return checkedEpisodeCntList[0]["cnt"] as int;
  }

  static getAllAnimeBytagName(String tagName, int offset, int number,
      {required AnimeSortCond animeSortCond}) async {
    Log.info("sql: getAllAnimeBytagName");

    dynamic list;
    SortCondItem sortCond =
        AnimeSortCond.sortConds[animeSortCond.specSortColumnIdx];
    if (sortCond.columnName == 'first_episode_watch_time') {
      list = await database.rawQuery('''
        select anime.*
        from anime left join history on anime.anime_id = history.anime_id
            and anime.review_number = history.review_number and history.episode_number = 1
        where anime.tag_name = '$tagName'
        -- Windows生效，Android不支持nulls last
        -- order by history.date ${animeSortCond.desc ? 'desc' : ''} nulls last;
        ${animeSortCond.desc ? 'order by IFNULL(history.date, \'0\') desc' : 'order by IFNULL(history.date, \'9\')'}
        limit $number offset $offset;
      ''');
    } else if (sortCond.columnName == 'recent_watch_time') {
      list = await database.rawQuery('''
        select anime.*
        from anime left join history on anime.anime_id = history.anime_id
            and anime.review_number = history.review_number
            -- 不能使用date，因为同一个动漫下，最大date可以有多个，会导致查询到多个重复动漫
            and history.episode_number = (
                select max(episode_number)
                from history
                where anime.anime_id = history.anime_id and anime.review_number = history.review_number
            )
        where anime.tag_name = '$tagName'
        ${animeSortCond.desc ? 'order by IFNULL(history.date, \'0\') desc' : 'order by IFNULL(history.date, \'9\')'}
        limit $number offset $offset;
      ''');
    } else {
      // COLLATE NOCASE 忽略大小写
      String orderSql = '''
        order by ${AnimeSortCond.sortConds[animeSortCond.specSortColumnIdx].columnName} COLLATE NOCASE
        ''';
      if (animeSortCond.desc) {
        orderSql += ' desc ';
      }

      list = await database.rawQuery('''
        select *
        from anime
        where tag_name = '$tagName'
        $orderSql
        limit $number offset $offset;
      '''); // 按anime_id倒序，保证最新添加的动漫在最上面
    }

    List<Anime> res = [];
    for (var element in list) {
      int animeId = element['anime_id'] as int;
      int reviewNumber = element['review_number'] as int;
      int checkedEpisodeCnt = await getCheckedEpisodeCntByAnimeId(animeId,
          reviewNumber: reviewNumber);
      bool hasJoinedSeries =
          (await AnimeSeriesDao.getSeriesIdListByAnimeId(animeId)).isNotEmpty;

      res.add(Anime(
        animeId: animeId,
        // 进入详细页面后需要该id
        animeName: element['anime_name'] as String,
        animeEpisodeCnt: element['anime_episode_cnt'] as int,
        // 详细地址和播放状态用于在收藏页更新全部动漫
        animeUrl: element['anime_url'] as String? ?? "",
        playStatus: element['play_status'] as String? ?? "",
        animeCoverUrl: element['anime_cover_url'] as String? ?? "",
        // 强制转换为String?，如果为null，则设置为空字符串
        tagName: tagName,
        // 必要：用于和从详细页面返回的新标签比较，看是否需要移动位置
        checkedEpisodeCnt: checkedEpisodeCnt,
        reviewNumber: reviewNumber,
        hasJoinedSeries: hasJoinedSeries,
      ));
    }
    return res;
  }

  static getAnimeCntPerTag() async {
    Log.info("sql: getAnimeCntPerTag");

    var list = await database.rawQuery('''
    select count(anime_id) as anime_cnt, tag.tag_name, tag.tag_order
    from tag left outer join anime -- sqlite只支持左外联结
        on anime.tag_name = tag.tag_name
    group by tag.tag_name -- 应该按照tag的tag_name分组
    order by tag.tag_order; -- 按照用户调整的顺序排序，否则会导致数量与实际不符
    ''');

    List<int> res = [];
    for (var item in list) {
      // Log.info(
      //     '${item['tag_name']}-${item['anime_cnt']}-${item['tag_order']}');
      res.add(item['anime_cnt'] as int);
    }
    return res;
  }

  static createTableEpisodeNote() async {
    await database.execute('''
    CREATE TABLE IF NOT EXISTS episode_note ( -- IF NOT EXISTS表示不存在表时才会创建
      note_id        INTEGER PRIMARY KEY AUTOINCREMENT,
      anime_id       INTEGER NOT NULL,
      episode_number INTEGER NOT NULL,
      note_content   TEXT,
      FOREIGN KEY (anime_id) REFERENCES anime (anime_id)
    );
    ''');
  }

  static createTableImage() async {
    await database.execute('''
    CREATE TABLE IF NOT EXISTS image (
      image_id          INTEGER  PRIMARY KEY AUTOINCREMENT,
      note_id           INTEGER,
      image_local_path  TEXT,
      image_url         TEXT,
      image_origin_name TEXT,
      FOREIGN KEY (note_id) REFERENCES episode_note (note_id)
    );
    ''');
  }

  static Future<int> insertNoteIdAndImageLocalPath(
      int noteId, String imageLocalPath, int orderIdx) async {
    Log.info(
        "sql: insertNoteIdAndLocalImg(noteId=$noteId, imageLocalPath=$imageLocalPath, orderIdx=$orderIdx)");
    return await database.rawInsert('''
    insert into image (note_id, image_local_path, order_idx)
    values ($noteId, '$imageLocalPath', $orderIdx);
    ''');
  }

  static deleteLocalImageByImageId(int imageId) async {
    Log.info("sql: deleteLocalImageByImageLocalPath($imageId)");
    await database.rawDelete('''
    delete from image
    where image_id = $imageId;
    ''');
  }

  static Future<Anime> getCustomAnimeByAnimeName(String animeName) async {
    animeName = EscapeUtil.escapeStr(animeName); // 先转义
    Log.info("sql: getCustomAnimeByAnimeName($animeName)");

    var list = await database.rawQuery('''
    select *
    from anime
    where anime_name = '$animeName' and (anime_url is null or length(anime_url) = 0); -- 只找该名字的动漫，且没有动漫地址
    ''');

    // 没找到，返回自定义动漫，用于添加
    if (list.isEmpty) {
      return Anime(
        animeName: animeName,
        animeEpisodeCnt: 0,
        animeCoverUrl: "",
      );
    }

    Anime anime =
        await AnimeDao.row2Bean(list[0], queryCheckedEpisodeCnt: true);
    return anime;
  }

  static Future<List<Anime>> getCustomAnimesIfContainAnimeName(
      String animeName) async {
    animeName = EscapeUtil.escapeStr(animeName); // 先转义
    Log.info("sql: getCustomAnimeByAnimeName($animeName)");

    var list = await database.rawQuery('''
    select *
    from anime
    where anime_name like '%$animeName%' and (anime_url is null or length(anime_url) = 0); -- 只找包含该名字的动漫，且没有动漫地址
    ''');

    List<Anime> res = [];
    for (var row in list) {
      Anime anime = await AnimeDao.row2Bean(row, queryCheckedEpisodeCnt: true);
      // 如果名字完全一样，则去掉，因为已经有了
      if (anime.animeName == animeName) continue;
    }

    return res;
  }

  static Future<void> createTableUpdateRecord() async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS update_record (
          id                 INTEGER PRIMARY KEY AUTOINCREMENT,
          anime_id           INTEGER NOT NULL,
          old_episode_cnt    INTEGER NOT NULL,
          new_episode_cnt    INTEGER NOT NULL,
          manual_update_time TEXT,
          FOREIGN KEY (
              anime_id
          )
          REFERENCES anime (anime_id)
      );
      ''');
  }

  static Future<void> addColumnOrderIdxToImage() async {
    var list = await database.rawQuery('''
    select * from sqlite_master where name = 'image' and sql like '%order_idx%';
    ''');
    // 没有列时添加
    if (list.isEmpty) {
      Log.info("sql: addColumnOrderIdxToImage");
      await database.execute('''
      alter table image
      add column order_idx INTEGER;
      ''');
    }
  }

  static Future<int> count(
      {required String tableName, String? columnName = 'id'}) async {
    final rows = await database
        .query(tableName, columns: ['COUNT(${columnName ?? "*"})']);
    return firstIntValue(rows);
  }

  static int firstIntValue(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return 0;
    return rows.first.values.firstWhere((element) => element is int) as int;
  }

  static T? firstRowColumnValue<T>(List<Map<String, Object?>> rows) {
    if (rows.isEmpty || rows.first.values.isEmpty) return null;
    final value = rows.first.values.first;
    return value is T ? value : null;
  }
}
