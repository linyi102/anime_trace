// ignore_for_file: avoid_debugPrint
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/episode.dart';
import 'package:flutter_test_future/classes/episode_note.dart';
import 'package:flutter_test_future/classes/history_plus.dart';
import 'package:flutter_test_future/classes/record.dart';
import 'package:flutter_test_future/classes/relative_local_image.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SqliteUtil {
  // 单例模式
  static SqliteUtil? _instance;

  SqliteUtil._();

  static Future<SqliteUtil> getInstance() async {
    _database = await _initDatabase();
    // for (int i = 0; i < 200; ++i) {
    //   await _database.rawInsert('''
    // insert into anime(anime_name, anime_episode_cnt, tag_name, last_mode_tag_time)
    // values('进击的巨人第一季', '24', '收集', '2021-12-10 20:23:22'), -- 手动添加是一定注意是两位数表示月日，否则会出错，比如6月>12月，因为6>1
    //     ('JOJO的奇妙冒险第六季 石之海', '12', '收集', '2021-12-09 20:23:22'),
    //     ('刀剑神域第一季', '24', '收集', '2021-12-08 20:23:22'),
    //     ('进击的巨人第二季', '12', '收集', '2021-12-07 20:23:22'),
    //     ('在下坂本，有何贵干？', '12', '终点', '2021-12-06 20:23:22');
    // ''');
    // }
    return _instance ??= SqliteUtil._();
  }

  static const sqlFileName = 'mydb.db';
  static late Database _database;
  static late String dbPath;

  static _initDatabase() async {
    if (Platform.isAndroid) {
      // dbPath = "${(await getExternalStorageDirectory())!.path}/$sqlFileName";
      dbPath = "${(await getApplicationSupportDirectory()).path}/$sqlFileName";
      debugPrint("👉android: path=$dbPath");
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
      debugPrint("👉windows: path=$dbPath");
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
    // await db.execute('''
    //   CREATE TABLE tag (
    //       tag_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    //       tag_name  TEXT    NOT NULL,
    //       tag_order INTEGER
    //       -- UNIQUE(tag_name)
    //   );
    //   ''');
    // 新增
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
    // for (int i = 0; i < 100; ++i) {
    //   await db.rawInsert('''
    // insert into anime(anime_name, anime_episode_cnt, tag_name, last_mode_tag_time)
    // values('进击的巨人第一季', '24', '收集', '2021-12-10 20:23:22'), -- 手动添加是一定注意是两位数表示月日，否则会出错，比如6月>12月，因为6>1
    //     ('JOJO的奇妙冒险第六季 石之海', '12', '收集', '2021-12-09 20:23:22'),
    //     ('刀剑神域第一季', '24', '收集', '2021-12-08 20:23:22'),
    //     ('进击的巨人第二季', '12', '收集', '2021-12-07 20:23:22'),
    //     ('在下坂本，有何贵干？', '12', '终点', '2021-12-06 20:23:22');
    // ''');
    // }
    // for (int i = 0; i < 1; ++i) {
    //   await db.rawInsert('''
    // insert into history(date, anime_id, episode_number)
    // values('2021-12-15 20:17:58', 2, 1),
    //     ('2021-12-15 20:23:22', 2, 3),
    //     ('2020-06-24 15:20:12', 1, 1),
    //     ('2021-12-04 14:11:27', 4, 2),
    //     ('2021-11-07 13:13:13', 3, 1),
    //     ('2021-10-07 12:12:12', 5, 2);
    // ''');
    // }
  }

  static void updateAnime(Anime oldAnime, Anime newAnime) async {
    debugPrint("sql: updateAnime");
    String datetime = DateTime.now().toString();
    debugPrint(
        "oldAnime.tagName=${oldAnime.tagName}, newAnime.tagName=${newAnime.tagName}");
    if (oldAnime.tagName != newAnime.tagName) {
      await _database.rawUpdate('''
      update anime
      set anime_name = '${newAnime.animeName}',
          anime_episode_cnt = ${newAnime.animeEpisodeCnt},
          tag_name = '${newAnime.tagName}',
          last_mode_tag_time = '$datetime' -- 更新最后修改标签的时间
      where anime_id = ${oldAnime.animeId};
      ''');
      debugPrint("last_mode_tag_time: $datetime");
    } else {
      await _database.rawUpdate('''
      update anime
      set anime_name = '${newAnime.animeName}',
          anime_episode_cnt = ${newAnime.animeEpisodeCnt}
      where anime_id = ${oldAnime.animeId};
      ''');
    }
  }

  static void updateAnimeNameByAnimeId(int animeId, String newAnimeName) async {
    debugPrint("sql: updateAnimeNameByAnimeId");
    newAnimeName =
        newAnimeName.replaceAll("'", "''"); // 将'替换为''，进行转义，否则会在插入时误认为'为边界
    await _database.rawUpdate('''
    update anime
    set anime_name = '$newAnimeName'
    where anime_id = $animeId;
    ''');
  }

  static void updateTagByAnimeId(int animeId, String newTagName) async {
    debugPrint("sql: updateTagNameByAnimeId");
    // 同时修改最后一次修改标签的时间
    await _database.rawUpdate('''
    update anime
    set tag_name = '$newTagName', last_mode_tag_time = '${DateTime.now().toString()}'
    where anime_id = $animeId;
    ''');
  }

  static void updateDescByAnimeId(int animeId, String desc) async {
    debugPrint("sql: updateDescByAnimeId");
    await _database.rawUpdate('''
    update anime
    set anime_desc = '$desc'
    where anime_id = $animeId;
    ''');
  }

  static void updateEpisodeCntByAnimeId(int animeId, int episodeCnt) async {
    debugPrint("sql: updateEpisodeCntByAnimeId");
    await _database.rawUpdate('''
    update anime
    set anime_episode_cnt = $episodeCnt
    where anime_id = $animeId;
    ''');
  }

  // 转义单引号
  static Anime escapeAnime(Anime anime) {
    anime.animeName = escapeStr(anime.animeName);
    return anime;
  }

  static String escapeStr(String str) {
    str = str.replaceAll("'", "''"); // 将'替换为''，进行转义，否则会在插入时误认为'为边界
    return str;
  }

  static Future<int> insertAnime(Anime anime) async {
    anime = escapeAnime(anime);
    debugPrint("sql: insertAnime(anime=$anime)");

    String datetime = DateTime.now().toString();
    return await _database.rawInsert('''
      insert into anime(anime_name, anime_episode_cnt, tag_name, last_mode_tag_time, anime_cover_url, cover_source)
      values('${anime.animeName}', '${anime.animeEpisodeCnt}', '${anime.tagName}', '$datetime', '${anime.animeCoverUrl}', '${anime.coverSource}');
    ''');
  }

  static Future<void> addColumnCoverToAnime() async {
    var list = await _database.rawQuery('''
    select * from sqlite_master where name = 'anime' and sql like '%anime_cover_url%';
    ''');
    // 没有列时添加
    if (list.isEmpty) {
      debugPrint("sql: addColumnCoverToAnime");
      await _database.execute('''
      alter table anime
      add column anime_cover_url TEXT;
      ''');
    }
  }

  static Future<void> addColumnInfoToAnime() async {
    Map<String, String> columns = {};
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
    columns.forEach((key, value) async {
      var list = await _database.rawQuery('''
    select * from sqlite_master where name = 'anime' and sql like '%$key%';
    ''');
      if (list.isEmpty) {
        await _database.execute('''
      alter table anime
      add column $key $value;
      ''');
      }
    });
  }

  // 为历史表和笔记表添加列：回顾号
  // 并将NULL改为1
  static Future<void> addColumnReviewNumberToHistoryAndNote() async {
    var list = await _database.rawQuery('''
    select * from sqlite_master where name = 'history' and sql like '%review_number%';
    ''');
    // 没有列时添加
    if (list.isEmpty) {
      debugPrint("sql: addColumnReviewNumberToHistoryAndNote");
      await _database.execute('''
      alter table history
      add column review_number INTEGER;
      ''');

      // 新增列才会修改NULL→1，之后就不修改了
      await _database.rawUpdate('''
      update history
      set review_number = 1
      where review_number is NULL;
      ''');
    }
    list = await _database.rawQuery('''
    select * from sqlite_master where name = 'episode_note' and sql like '%review_number%';
    ''');
    // 没有列时添加
    if (list.isEmpty) {
      debugPrint("sql: addColumnReviewNumberToHistoryAndNote");
      await _database.execute('''
      alter table episode_note
      add column review_number INTEGER;
      ''');

      await _database.rawUpdate('''
      update episode_note
      set review_number = 1
      where review_number is NULL;
      ''');
    }
  }

  // 为动漫表添加列：图片的搜索源
  // 添加动漫、更改封面时都会用到该列
  static Future<void> addColumnCoverSourceToAnime() async {
    var list = await _database.rawQuery('''
    select * from sqlite_master where name = 'anime' and sql like '%cover_source%';
    ''');
    // 没有列时添加
    if (list.isEmpty) {
      debugPrint("sql: addColumnCoverSourceToAnime");
      await _database.execute('''
      alter table anime
      add column cover_source TEXT;
      ''');

      // 新增列才会修改NULL→1，之后就不修改了
      await _database.rawUpdate('''
      update anime
      set cover_source = '樱花动漫'
      where cover_source is NULL;
      ''');
    }
  }

  static Future<void> updateAnimeCoverbyAnimeId(
      int animeId, String? coverUrl) async {
    debugPrint("sql: updateAnimeCoverbyAnimeId");
    String coverSource = SPUtil.getString("selectedWebsite");

    await _database.rawUpdate('''
    update anime
    set anime_cover_url = '$coverUrl', cover_source = '$coverSource'
    where anime_id = $animeId;
    ''');
  }

  static void insertHistoryItem(
      int animeId, int episodeNumber, String date, int reviewNumber) async {
    debugPrint(
        "sql: insertHistoryItem(animeId=$animeId, episodeNumber=$episodeNumber, date=$date, reviewNumber=$reviewNumber)");
    await _database.rawInsert('''
    insert into history(date, anime_id, episode_number, review_number)
    values('$date', $animeId, $episodeNumber, $reviewNumber);
    ''');
  }

  static void updateHistoryItem(
      int animeId, int episodeNumber, String date, int reviewNumber) async {
    debugPrint("sql: updateHistoryItem");

    await _database.rawInsert('''
    update history
    set date = '$date'
    where anime_id = $animeId and episode_number = $episodeNumber and review_number = $reviewNumber;
    ''');
  }

  static void deleteHistoryItemByAnimeIdAndEpisodeNumberAndReviewNumber(
      int animeId, int episodeNumber, int reviewNumber) async {
    debugPrint(
        "sql: deleteHistoryItemByAnimeIdAndEpisodeNumberAndReviewNumber(animeId=$animeId, episodeNumber=$episodeNumber)");
    await _database.rawDelete('''
    delete from history
    where anime_id = $animeId and episode_number = $episodeNumber and review_number = $reviewNumber;
    ''');
  }

  static void deleteAnimeByAnimeId(int animeId) async {
    debugPrint("sql: deleteAnimeByAnimeId");
    // 由于history表引用了anime表的anime_id，首先删除历史记录，再删除动漫
    await _database.rawDelete('''
    delete from history
    where anime_id = $animeId;
    ''');
    await _database.rawDelete('''
    delete from anime
    where anime_id = $animeId;
    ''');
  }

  static void insertTagName(String tagName, int tagOrder) async {
    debugPrint("sql: insertTagName");
    await _database.rawInsert('''
    insert into tag(tag_name, tag_order)
    values('$tagName', $tagOrder);
    ''');
  }

  static void updateTagName(String oldTagName, String newTagName) async {
    debugPrint("sql: updateTagNameByTagId");
    await _database.rawUpdate('''
      update tag
      set tag_name = '$newTagName'
      where tag_name = '$oldTagName';
    ''');
    // 更改tag表的tag_name后，还需要更改动漫表中的tag_name列
    await _database.rawUpdate('''
      update anime
      set tag_name = '$newTagName'
      where tag_name = '$oldTagName';
    ''');
  }

  static Future<bool> updateTagOrder(List<String> tagNames) async {
    debugPrint("sql: updateTagOrder");
    // 错误：把表中标签的名字和list中对应起来即可。这样会导致动漫标签不匹配
    // 应该重建一个order列，从0开始
    for (int i = 0; i < tagNames.length; ++i) {
      await _database.rawUpdate('''
      update tag
      set tag_order = $i 
      where tag_name = '${tagNames[i]}';
      ''');
    }
    return true;
  }

  static void deleteTagByTagName(String tagName) async {
    debugPrint("sql: deleteTagByTagName");
    await _database.rawDelete('''
    delete from tag
    where tag_name = '$tagName';
    ''');
  }

  static Future<List<String>> getAllTags() async {
    debugPrint("sql: getAllTags");
    var list = await _database.rawQuery('''
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
    debugPrint("sql: getAnimeByAnimeId($animeId)");

    var list = await _database.rawQuery('''
    select anime_name, anime_episode_cnt, tag_name, anime_desc, anime_cover_url, cover_source
    from anime
    where anime_id = $animeId;
    ''');
    if (list.isEmpty) {
      debugPrint("不应该啊");
    }
    int maxReviewNumber = await getMaxReviewNumberByAnimeId(animeId);
    int checkedEpisodeCnt = await getCheckedEpisodeCntByAnimeId(animeId,
        maxReviewNumber: maxReviewNumber);

    Anime anime = Anime(
      animeId: animeId,
      animeName: list[0]['anime_name'] as String,
      animeEpisodeCnt: list[0]['anime_episode_cnt'] as int,
      animeDesc: list[0]['anime_desc'] as String? ?? "", // 如果为null，则返回空串
      animeCoverUrl: list[0]['anime_cover_url'] as String? ?? "",
      tagName: list[0]['tag_name'] as String,
      checkedEpisodeCnt: checkedEpisodeCnt,
      reviewNumber: maxReviewNumber,
      coverSource: list[0]['cover_source'] as String,
    );
    return anime;
  }

  static Future<Anime> getAnimeByAnimeNameAndSource(Anime anime) async {
    // debugPrint("sql: getAnimeIdByAnimeNameAndSource()");
    var list = await _database.rawQuery('''
      select anime_id, anime_name, anime_episode_cnt, tag_name, anime_desc, anime_cover_url, cover_source
      from anime
      where anime_name = '${anime.animeName}' and cover_source = '${anime.coverSource}';
    ''');
    // 为空返回旧对象
    if (list.isEmpty) {
      return anime;
    }
    int animeId = list[0]['anime_id'] as int;
    int maxReviewNumber = await getMaxReviewNumberByAnimeId(animeId);
    int checkedEpisodeCnt = await getCheckedEpisodeCntByAnimeId(animeId,
        maxReviewNumber: maxReviewNumber);
    Anime searchedanime = Anime(
      animeId: animeId,
      animeName: list[0]['anime_name'] as String,
      animeEpisodeCnt: list[0]['anime_episode_cnt'] as int,
      animeDesc: list[0]['anime_desc'] as String? ?? "", // 如果为null，则返回空串
      animeCoverUrl: list[0]['anime_cover_url'] as String? ?? "",
      tagName: list[0]['tag_name'] as String,
      checkedEpisodeCnt: checkedEpisodeCnt,
      reviewNumber: maxReviewNumber,
      coverSource: list[0]['cover_source'] as String,
    );
    return searchedanime;
  }

  static Future<int> getAnimeLastId() async {
    debugPrint("sql: getAnimeLastId");
    var list = await _database.rawQuery('''
    select last_insert_rowid() as last_id
    from anime;
    ''');
    int lastId = list[0]["last_id"] as int;
    debugPrint("sql: getAnimeLastId=$lastId");
    return lastId;
  }

  static Future<String> getTagNameByAnimeId(int animeId) async {
    debugPrint("sql: getTagNameByAnimeId");
    var list = await _database.rawQuery('''
    select tag_name
    from anime
    where anime.anime_id = $animeId;
    ''');
    return list[0]['tag_name'] as String;
  }

  static Future<List<Episode>> getEpisodeHistoryByAnimeIdAndReviewNumber(
      Anime anime, int reviewNumber) async {
    debugPrint(
        "sql: getEpisodeHistoryByAnimeIdAndReviewNumber(animeId=${anime.animeId}, reviewNumber=$reviewNumber)");
    int animeEpisodeCnt = anime.animeEpisodeCnt;

    var list = await _database.rawQuery('''
    select date, episode_number
    from anime inner join history
        on anime.anime_id = ${anime.animeId} and anime.anime_id = history.anime_id and history.review_number = $reviewNumber;
    ''');
    // debugPrint("查询结果：$list");
    List<Episode> episodes = [];
    for (int episodeNumber = 1;
        episodeNumber <= animeEpisodeCnt;
        ++episodeNumber) {
      episodes.add(Episode(episodeNumber, reviewNumber));
    }
    // 遍历查询结果，每个元素都是一个键值对(列名-值)
    for (var element in list) {
      int episodeNumber = element['episode_number'] as int;
      episodes[episodeNumber - 1].dateTime = element['date'] as String;
    }
    return episodes;
  }

  static Future<int> getAnimesCntBytagName(String tagName) async {
    debugPrint("sql: getAnimesCntBytagName");
    var list = await _database.rawQuery('''
    select count(anime.anime_id) cnt
    from anime
    where anime.tag_name = '$tagName';
    ''');
    return list[0]["cnt"] as int;
  }

  static Future<List<Anime>> getAnimesBySearch(String keyWord) async {
    debugPrint("sql: getAnimesBySearch");
    keyWord = escapeStr(keyWord);

    var list = await _database.rawQuery('''
    select anime_id, anime_name, anime_episode_cnt, anime_cover_url
    from anime
    where anime_name LIKE '%$keyWord%';
    ''');

    List<Anime> res = [];
    for (var element in list) {
      // var checkedEpisodeCntList = await _database.rawQuery('''
      // select count(anime.anime_id) cnt
      // from anime inner join history
      //     on anime.anime_id = ${element['anime_id']} and anime.anime_id = history.anime_id;
      // ''');
      int animeId = element['anime_id'] as int;
      int maxReviewNumber =
          await SqliteUtil.getMaxReviewNumberByAnimeId(animeId);
      int checkedEpisodeCnt = await SqliteUtil.getCheckedEpisodeCntByAnimeId(
          animeId,
          maxReviewNumber: maxReviewNumber);

      res.add(Anime(
        animeId: animeId, // 进入详细页面后需要该id
        animeName: element['anime_name'] as String,
        animeEpisodeCnt: element['anime_episode_cnt'] as int,
        checkedEpisodeCnt: checkedEpisodeCnt,
        animeCoverUrl: element['anime_cover_url'] as String? ?? "",
        reviewNumber: maxReviewNumber,
      ));
    }
    return res;
  }

  static Future<int> getMaxReviewNumberByAnimeId(int animeId) async {
    // debugPrint("getMaxReviewNumberByAnimeId(animeId=$animeId)");
    // 新增回顾号列后，不能简单从历史表中计数来获取进度了
    // 而是先得到该动漫的最大回顾号，然后根据该回顾号计数
    var maxReviewNumberList = await _database.rawQuery('''
      select max(review_number) max_review_number
      from history
      where history.anime_id = $animeId;
      ''');
    // 有些动漫没有进度，所以没有回顾号，此时返回的表有一行，结果为NULL，此时默认为1即可
    int maxReviewNumber =
        maxReviewNumberList[0]["max_review_number"] as int? ?? 1;
    return maxReviewNumber;
  }

  static Future<int> getCheckedEpisodeCntByAnimeId(int animeId,
      {int maxReviewNumber = 0}) async {
    // debugPrint("getCheckedEpisodeCntByAnimeId(animeId=$animeId)");
    // 如果已经给了最大回顾号，则不用再查找。因为要求动漫列表也显示最大回顾号，所以查询的时候会先查询最大回顾号，然后存放在Anime中
    if (maxReviewNumber == 0) {
      maxReviewNumber = await getMaxReviewNumberByAnimeId(animeId);
    }

    var checkedEpisodeCntList = await _database.rawQuery('''
      select count(anime.anime_id) cnt
      from anime inner join history
          on anime.anime_id = $animeId and anime.anime_id = history.anime_id and review_number = $maxReviewNumber;
      ''');
    // debugPrint(
    //     "最大回顾号$maxReviewNumber的进度：checkedEpisodeCnt=${checkedEpisodeCntList[0]["cnt"] as int}");
    return checkedEpisodeCntList[0]["cnt"] as int;
  }

  static getAllAnimeBytagName(String tagName, int offset, int number) async {
    debugPrint("sql: getAllAnimeBytagName");

    var list = await _database.rawQuery('''
    select anime_id, anime_name, anime_episode_cnt, tag_name, anime_cover_url
    from anime
    where tag_name = '$tagName'
    order by last_mode_tag_time desc -- 按最后修改标签时间倒序排序，保证最新修改标签在列表上面
    limit $number offset $offset;
    '''); // 按anime_id倒序，保证最新添加的动漫在最上面

    List<Anime> res = [];
    for (var element in list) {
      int animeId = element['anime_id'] as int;
      int maxReviewNumber = await getMaxReviewNumberByAnimeId(animeId);
      int checkedEpisodeCnt = await getCheckedEpisodeCntByAnimeId(animeId,
          maxReviewNumber: maxReviewNumber);

      res.add(Anime(
          animeId: animeId, // 进入详细页面后需要该id
          animeName: element['anime_name'] as String,
          animeEpisodeCnt: element['anime_episode_cnt'] as int,
          animeCoverUrl: element['anime_cover_url'] as String? ??
              "", // 强制转换为String?，如果为null，则设置为空字符串
          tagName: tagName, // 必要：用于和从详细页面返回的新标签比较，看是否需要移动位置
          checkedEpisodeCnt: checkedEpisodeCnt,
          reviewNumber: maxReviewNumber));
    }
    return res;
  }

  static Future<List<Anime>> getAllAnimes() async {
    debugPrint("sql: getAllAnimes");

    var list = await _database.rawQuery('''
    select anime_id, anime_name, anime_cover_url
    from anime;
    ''');

    List<Anime> res = [];
    for (var element in list) {
      res.add(Anime(
        animeId: element['anime_id'] as int,
        animeName: element['anime_name'] as String,
        animeEpisodeCnt: 0,
        animeCoverUrl: element['anime_cover_url'] as String? ?? "",
      ));
    }
    return res;
  }

  static getAnimeCntPerTag() async {
    debugPrint("sql: getAnimeCntPerTag");

    var list = await _database.rawQuery('''
    select count(anime_id) as anime_cnt, tag.tag_name, tag.tag_order
    from tag left outer join anime -- sqlite只支持左外联结
        on anime.tag_name = tag.tag_name
    group by tag.tag_name -- 应该按照tag的tag_name分组
    order by tag.tag_order; -- 按照用户调整的顺序排序，否则会导致数量与实际不符
    ''');

    List<int> res = [];
    for (var item in list) {
      // debugPrint(
      //     '${item['tag_name']}-${item['anime_cnt']}-${item['tag_order']}');
      res.add(item['anime_cnt'] as int);
    }
    return res;
  }

  // static Future<List<HistoryPlus>> getAllHistoryPlus() async {
  //   debugPrint("sql: getAllHistoryPlus");
  //   String earliestDate;
  //   // earliestDate = SPUtil.getString("earliest_date", defaultValue: "");
  //   // if (earliestDate.isEmpty) {
  //   var list = await _database.rawQuery('''
  //     select min(date) min_date
  //     from history;
  //     ''');
  //   if (list[0]['min_date'] == null) return []; // 还没有历史，直接返回，否则强制转为String会报错
  //   earliestDate = list[0]['min_date'] as String;
  //   //   SPUtil.setString("earliest_date", earliestDate);
  //   // }
  //   debugPrint("最早日期为：$earliestDate");
  //   DateTime earliestDateTime = DateTime.parse(earliestDate);
  //   int earliestYear = earliestDateTime.year;
  //   int earliestMonth = earliestDateTime.month;

  //   // 先找到该月看的所有动漫id，然后根据动漫id去重，再根据动漫id得到当月看的最小值和最大值
  //   List<HistoryPlus> history = [];
  //   DateTime now = DateTime.now();
  //   int curMonth = now.month;
  //   int curYear = now.year;
  //   for (int year = curYear; year >= earliestYear; --year) {
  //     int month = curMonth;
  //     int border = 1;
  //     if (year != curYear) month = 12;
  //     if (year == earliestYear) border = earliestMonth;
  //     for (; month >= border; --month) {
  //       String date;
  //       if (month >= 10) {
  //         date = "$year-$month";
  //       } else {
  //         date = "$year-0$month";
  //       }
  //       var list = await _database.rawQuery('''
  //       select distinct anime.anime_id, anime.anime_name
  //       from history, anime
  //       where date like '$date%' and history.anime_id = anime.anime_id
  //       order by date desc; -- 倒序
  //       ''');
  //       List<Anime> animes = [];
  //       for (var item in list) {
  //         animes.add(Anime(
  //             animeId: item['anime_id'] as int,
  //             animeName: item['anime_name'] as String,
  //             animeEpisodeCnt: 0));
  //       }
  //       if (animes.isEmpty) continue; // 没有观看记录时直接跳过

  //       List<Record> records = [];
  //       // 对于每个动漫，找到当月观看的最小值的最大值
  //       for (var anime in animes) {
  //         // debugPrint(anime);
  //         list = await _database.rawQuery('''
  //         select min(episode_number) as start
  //         from history
  //         where date like '$date%' and anime_id = ${anime.animeId};
  //         ''');
  //         int startEpisodeNumber = list[0]['start'] as int;
  //         list = await _database.rawQuery('''
  //         select max(episode_number) as end
  //         from history
  //         where date like '$date%' and anime_id = ${anime.animeId};
  //         ''');
  //         int endEpisodeNumber = list[0]['end'] as int;
  //         Record record = Record(anime, startEpisodeNumber, endEpisodeNumber);
  //         // debugPrint(record);
  //         records.add(record);
  //       }
  //       history.add(HistoryPlus(date, records));
  //     }
  //   }
  //   // for (var item in history) {
  //   //   debugPrint(item);
  //   // }
  //   return history;
  // }

  static Future<List<HistoryPlus>> getAllHistoryByYear(int year) async {
    debugPrint("sql: getAllHistoryByYear");

    // 整体思路：先找到该月看的所有动漫id，然后根据动漫id去重，再根据动漫id得到当月看的最小值和最大值
    // 新增回顾号列后，最小值和最大值应该属于同一回顾号
    List<HistoryPlus> history = [];

    // 如果存在临时表，则删除
    await _database.execute('''
      drop table if exists history_year;
      ''');
    // 优化：先只选出该年的记录，作为临时表。记得删除该表(放在上面比较好)
    await _database.execute('''
      create temp table history_year as
      select * from history
      where date like '$year%';
      ''');

    for (int month = 12; month >= 1; --month) {
      String date;
      if (month >= 10) {
        date = "$year-$month";
      } else {
        date = "$year-0$month";
      }
      var list = await _database.rawQuery('''
        select distinct anime.anime_id, anime.anime_name, anime.anime_cover_url
        from history_year, anime
        where date like '$date%' and history_year.anime_id = anime.anime_id
        order by date desc; -- 倒序
        ''');
      List<Anime> animes = [];
      for (var item in list) {
        animes.add(Anime(
            animeId: item['anime_id'] as int,
            animeName: item['anime_name'] as String,
            animeEpisodeCnt: 0,
            animeCoverUrl: item['anime_cover_url'] as String? ?? ""));
      }
      if (animes.isEmpty) continue; // 没有观看记录时直接跳过

      List<Record> records = [];
      // 对于每个动漫，找到当月观看的最小值和最大值
      // 如果该月存在多个回顾号，注意要挑选的最小值和最大值的回顾号一样
      // 因此需要先找出该月存在的该动漫的所有回顾号(注意去重)，对与每个回顾号
      // 都要找出min和max，并添加到records中
      for (var anime in animes) {
        // debugPrint(anime);
        var reviewNumberList = await _database.rawQuery('''
        select distinct review_number
        from history_year
        where date like '$date%' and anime_id = ${anime.animeId};
        ''');
        for (var reviewNumberElem in reviewNumberList) {
          int reviewNumber = reviewNumberElem['review_number'] as int;
          list = await _database.rawQuery('''
          select min(episode_number) as start
          from history_year
          where date like '$date%' and anime_id = ${anime.animeId} and review_number = $reviewNumber;
          ''');
          int startEpisodeNumber = list[0]['start'] as int;
          list = await _database.rawQuery('''
          select max(episode_number) as end
          from history_year
          where date like '$date%' and anime_id = ${anime.animeId} and review_number = $reviewNumber;
          ''');
          int endEpisodeNumber = list[0]['end'] as int;
          Record record =
              Record(anime, reviewNumber, startEpisodeNumber, endEpisodeNumber);
          // debugPrint(record);
          records.add(record);
        }
      }
      history.add(HistoryPlus(date, records));
    }
    // for (var item in history) {
    //   debugPrint(item);
    // }
    return history;
  }

  static createTableEpisodeNote() async {
    await _database.execute('''
    CREATE TABLE IF NOT EXISTS episode_note ( -- IF NOT EXISTS表示不存在表时才会创建
      note_id        INTEGER PRIMARY KEY AUTOINCREMENT,
      anime_id       INTEGER NOT NULL,
      episode_number INTEGER NOT NULL,
      note_content   TEXT,
      FOREIGN KEY (anime_id) REFERENCES anime (anime_id) 
    );
    ''');
  }

  static Future<int> insertEpisodeNote(EpisodeNote episodeNote) async {
    debugPrint(
        "sql: insertEpisodeNote(animeId=${episodeNote.anime.animeId}, episodeNumber=${episodeNote.episode.number}, reviewNumber=${episodeNote.episode.reviewNumber})");
    await _database.rawInsert('''
    insert into episode_note (anime_id, episode_number, review_number, note_content)
    values (${episodeNote.anime.animeId}, ${episodeNote.episode.number}, ${episodeNote.episode.reviewNumber}, ''); -- 空内容
    ''');

    var lm2 = await _database.rawQuery('''
      select last_insert_rowid() as last_id
      from episode_note;
      ''');
    return lm2[0]["last_id"] as int; // 返回最新插入的id
  }

  static updateEpisodeNoteContentByNoteId(
      int noteId, String noteContent) async {
    debugPrint("sql: updateEpisodeNoteContent($noteId, $noteContent)");
    debugPrint("笔记id：$noteId, 笔记内容：$noteContent");
    await _database.rawUpdate('''
    update episode_note
    set note_content = '$noteContent'
    where note_id = $noteId;
    ''');
  }

  static Future<EpisodeNote>
      getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(
          EpisodeNote episodeNote) async {
    debugPrint(
        "sql: getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(episodeNumber=${episodeNote.episode.number}, review_number=${episodeNote.episode.reviewNumber})");
    // 查询内容
    var lm1 = await _database.rawQuery('''
    select note_id, note_content from episode_note
    where anime_id = ${episodeNote.anime.animeId} and episode_number = ${episodeNote.episode.number} and review_number = ${episodeNote.episode.reviewNumber};
    ''');
    if (lm1.isEmpty) {
      // 如果没有则插入笔记(为了兼容之前完成某集后不会插入空笔记)
      episodeNote.episodeNoteId = await insertEpisodeNote(episodeNote);
    } else {
      episodeNote.episodeNoteId = lm1[0]['note_id'] as int;
      // 获取笔记内容
      episodeNote.noteContent = lm1[0]['note_content'] as String;
    }
    // debugPrint("笔记${episodeNote.episodeNoteId}内容：${episodeNote.noteContent}");
    // 查询图片
    episodeNote.relativeLocalImages =
        await getRelativeLocalImgsByNoteId(episodeNote.episodeNoteId);
    return episodeNote;
  }

  static Future<List<EpisodeNote>> getAllNotesByTableHistory() async {
    debugPrint("sql: getAllNotesByTableHistory");
    List<EpisodeNote> episodeNotes = [];
    // 根据history表中的anime_id和episode_number来获取相应的笔记，并按时间倒序排序
    var lm1 = await _database.rawQuery('''
    select date, history.anime_id, episode_number, anime_name, anime_cover_url, review_number
    from history inner join anime on history.anime_id = anime.anime_id
    order by date desc;
    ''');
    for (var item in lm1) {
      Anime anime = Anime(
          animeId: item['anime_id'] as int,
          animeName: item['anime_name'] as String,
          animeEpisodeCnt: 0,
          animeCoverUrl: item['anime_cover_url'] as String);
      Episode episode = Episode(
        item['episode_number'] as int,
        item['review_number'] as int,
        dateTime: item['date'] as String,
      );
      EpisodeNote episodeNote = EpisodeNote(
          anime: anime, episode: episode, relativeLocalImages: [], imgUrls: []);
      episodeNote =
          await getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(
              episodeNote);
      // debugPrint(episodeNote);
      episodeNote.relativeLocalImages =
          await getRelativeLocalImgsByNoteId(episodeNote.episodeNoteId);
      episodeNotes.add(episodeNote);
    }
    return episodeNotes;
  }

  //↓优化
  static Future<List<EpisodeNote>> getAllNotesByTableNote(
      int offset, int number) async {
    debugPrint("sql: getAllNotesByTableNote");
    List<EpisodeNote> episodeNotes = [];
    // 根据笔记中的动漫id和集数number(还有回顾号review_number)，即可获取到完成时间，根据动漫id，获取动漫封面
    // 因为pageSize个笔记中有些笔记没有内容和图片，在之后会过滤掉，所以并不会得到pageSize个笔记，从而导致滑动到最下面也不够pageSize个，而无法再次请求
    var lm1 = await _database.rawQuery('''
    select episode_note.note_id, episode_note.note_content, episode_note.anime_id, episode_note.episode_number, history.date, anime.anime_name, anime.anime_cover_url, episode_note.review_number
    from episode_note, anime, history
    where episode_note.anime_id = anime.anime_id and episode_note.anime_id = history.anime_id and episode_note.episode_number = history.episode_number and episode_note.review_number = history.review_number
    order by history.date desc
    limit $number offset $offset;
    ''');
    for (var item in lm1) {
      Anime anime = Anime(
          animeId: item['anime_id'] as int, // 不能写成episode_note.anime_id，下面也是
          animeName: item['anime_name'] as String,
          animeCoverUrl: item['anime_cover_url'] as String,
          animeEpisodeCnt: 0);
      Episode episode = Episode(
        item['episode_number'] as int,
        item['review_number'] as int,
        dateTime: item['date'] as String,
      );
      List<RelativeLocalImage> relativeLocalImages =
          await getRelativeLocalImgsByNoteId(item['note_id'] as int);
      EpisodeNote episodeNote = EpisodeNote(
          episodeNoteId: item['note_id'] as int, // 忘记设置了，导致都是进入笔记0
          anime: anime,
          episode: episode,
          noteContent: item['note_content'] as String,
          relativeLocalImages: relativeLocalImages,
          imgUrls: []);
      // // 如果没有图片，且笔记内容为空，则不添加。会导致无法显示分页查询
      // if (episodeNote.relativeLocalImages.isEmpty &&
      //     episodeNote.noteContent.isEmpty) continue;
      episodeNotes.add(episodeNote);
    }
    return episodeNotes;
  }

  static createTableImage() async {
    await _database.execute('''
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
      int noteId, String imageLocalPath) async {
    debugPrint("sql: insertNoteIdAndLocalImg($noteId, $imageLocalPath)");
    return await _database.rawInsert('''
    insert into image (note_id, image_local_path)
    values ($noteId, '$imageLocalPath');
    ''');
  }

  static deleteLocalImageByImageId(int imageId) async {
    debugPrint("sql: deleteLocalImageByImageLocalPath($imageId)");
    await _database.rawDelete('''
    delete from image
    where image_id = $imageId;
    ''');
  }

  static Future<List<RelativeLocalImage>> getRelativeLocalImgsByNoteId(
      int noteId) async {
    var lm = await _database.rawQuery('''
    select image_id, image_local_path from image
    where note_id = $noteId;
    ''');
    List<RelativeLocalImage> relativeLocalImages = [];
    for (var item in lm) {
      relativeLocalImages.add(RelativeLocalImage(
          item['image_id'] as int, item['image_local_path'] as String));
    }
    return relativeLocalImages;
  }
}
