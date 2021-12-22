// ignore_for_file: avoid_print
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/history.dart';
import 'package:flutter_test_future/classes/episode.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SqliteUtil {
  // 单例模式
  static SqliteUtil? _instance;

  SqliteUtil._();

  static Future<SqliteUtil> getInstance() async {
    _database = await _initDatabase();
    return _instance ??= SqliteUtil._();
  }

  static const sqlFileName = 'mydb.db';
  static late Database _database;
  static late String dbPath;

  static _initDatabase() async {
    dbPath = "${(await getExternalStorageDirectory())!.path}/$sqlFileName";
    // String path = "${await getDatabasesPath()}/$sqlFileName";

    print("👉path=$dbPath");
    await deleteDatabase(dbPath); // 删除数据库
    return await openDatabase(
      dbPath,
      onCreate: (Database db, int version) {
        _createInitTable(db); // 只会在数据库创建时才会创建表，记得传入的是db，而不是databse
        _insertInitData(db);
      },
      version: 1, // onCreate must be null if no version is specified
    );
  }

  static void _createInitTable(Database db) async {
    await db.execute('''
      CREATE TABLE tag (
          tag_id    INTEGER PRIMARY KEY AUTOINCREMENT,
          tag_name  TEXT    NOT NULL,
          tag_order INTEGER
          -- UNIQUE(tag_name)
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
  }

  static void _insertInitData(Database db) async {
    await db.rawInsert('''
      insert into tag(tag_name, tag_order)
      -- values('拾'), ('途'), ('终'), ('搁'), ('弃');
      values('拾', 1), ('途', 2), ('终', 3);
    ''');
    for (int i = 0; i < 1; ++i) {
      await db.rawInsert('''
      insert into anime(anime_name, anime_episode_cnt, tag_name)
      values('进击的巨人第一季', '24', '拾'),
          ('JOJO的奇妙冒险第六季 石之海', '12', '拾'),
          ('刀剑神域第一季', '24', '拾'),
          ('进击的巨人第二季', '12', '拾'),
          ('在下坂本，有何贵干？', '12', '终');
    ''');
    }
    await db.rawInsert('''
      insert into history(date, anime_id, episode_number)
      values('2021-12-15 20:17:58', 2, 1),
          ('2021-12-15 20:23:22', 2, 3),
          ('2020-06-24 15:20:12', 1, 1),
          ('2021-12-04 14:11:27', 4, 2),
          ('2021-11-07 13:13:13', 3, 1),
          ('2021-10-07 12:12:12', 5, 2);
    ''');
  }

  static void updateAnime(int animeId, Anime newAnime) async {
    // int count =
    await _database.rawUpdate('''
    update anime
    set anime_name = '${newAnime.animeName}',
        anime_episode_cnt = ${newAnime.animeEpisodeCnt},
        tag_name = '${newAnime.tagName}'
    where anime_id = $animeId;
    ''');
    // print("count=$count");
  }

  static void insertAnime(Anime anime) async {
    print("sql: insertAnime");
    await _database.rawInsert('''
    insert into anime(anime_name, anime_episode_cnt, tag_name)
    values('${anime.animeName}', '${anime.animeEpisodeCnt}', '${anime.tagName}');
    ''');
  }

  static void insertHistoryItem(int animeId, int episodeNumber) async {
    String date = DateTime.now().toString();

    await _database.rawInsert('''
    insert into history(date, anime_id, episode_number)
    values('$date', $animeId, $episodeNumber);
    ''');
  }

  static void deleteHistoryItem(String? date) async {
    await _database.rawDelete('''
    delete from history
    where date = '$date';
    ''');
  }

  static void insertTagName(String tagName, int tagOrder) async {
    print("sql: insertTagName");
    await _database.rawInsert('''
    insert into tag(tag_name, tag_order)
    values('$tagName', $tagOrder);
    ''');
  }

  static void updateTagNameByTagName(
      String oldTagName, String newTagName) async {
    print("sql: updateTagNameByTagId");
    await _database.rawUpdate('''
    update tag
    set tag_name = '$newTagName'
    where tag_name = '$oldTagName';
    ''');
  }

  static Future<bool> updateTagOrder(List<String> tagNames) async {
    print("sql: updateTagOrder");
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
    print("sql: deleteTagByTagName");
    await _database.rawDelete('''
    delete from tag
    where tag_name = '$tagName';
    ''');
  }

  static Future<List<String>> getAllTags() async {
    print("sql: getAllTags");
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
    print("sql: getAnimeByAnimeId");
    var list = await _database.rawQuery('''
    select anime_name, anime_episode_cnt, tag_name
    from anime
    where anime_id = $animeId;
    ''');
    Anime anime = Anime(
        animeName: list[0]['anime_name'] as String,
        animeEpisodeCnt: list[0]['anime_episode_cnt'] as int,
        tagName: list[0]['tag_name'] as String);
    return anime;
  }

  static Future<int> getAnimeLastId() async {
    var list = await _database.rawQuery('''
    select last_insert_rowid() as last_id
    from anime;
    ''');
    int lastId = list[0]["last_id"] as int;
    print("sql: getAnimeLastId=$lastId");
    return lastId;
  }

  static Future<String> getTagNameByAnimeId(int animeId) async {
    print("sql: getTagNameByAnimeId");
    var list = await _database.rawQuery('''
    select tag_name
    from anime
    where anime.anime_id = $animeId;
    ''');
    return list[0]['tag_name'] as String;
  }

  static Future<List<Episode>> getAnimeEpisodeHistoryById(int animeId) async {
    print("sql: getAnimeEpisodeHistoryById");
    Anime anime = await getAnimeByAnimeId(animeId);
    int animeEpisodeCnt = anime.animeEpisodeCnt;

    var list = await _database.rawQuery('''
    select date, episode_number
    from anime inner join history
        on anime.anime_id = $animeId and anime.anime_id = history.anime_id;
    ''');
    // print("查询结果：$list");
    List<Episode> episodes = [];
    for (int episodeNumber = 1;
        episodeNumber <= animeEpisodeCnt;
        ++episodeNumber) {
      episodes.add(Episode(episodeNumber));
    }
    // 遍历查询结果，每个元素都是一个键值对(列名-值)
    for (var element in list) {
      int episodeNumber = element['episode_number'] as int;
      episodes[episodeNumber - 1].dateTime = element['date'] as String;
    }
    return episodes;
  }

  static Future<int> getAnimesCntBytagName(String tagName) async {
    var list = await _database.rawQuery('''
    select count(anime.anime_id) cnt
    from anime
    where anime.tag_name = '$tagName';
    ''');
    return list[0]["cnt"] as int;
  }

  static getAllAnimeBytagName(String tagName) async {
    print("sql: getAllAnimeBytagName");

    var list = await _database.rawQuery('''
    select anime_id, anime_name, anime_episode_cnt
    from anime
    where tag_name = '$tagName'
    order by anime_id desc;
    // limit 100 offset 0;
    '''); // 按anime_id倒序，保证最新添加的动漫在最上面

    List<Anime> res = [];
    for (var element in list) {
      var checkedEpisodeCntList = await _database.rawQuery('''
      select count(anime.anime_id) cnt
      from anime inner join history
          on anime.anime_id = ${element['anime_id']} and anime.anime_id = history.anime_id;
      ''');
      int checkedEpisodeCnt = checkedEpisodeCntList[0]["cnt"] as int;

      res.add(Anime(
        animeId: element['anime_id'] as int, // 进入详细页面后需要该id
        animeName: element['anime_name'] as String,
        animeEpisodeCnt: element['anime_episode_cnt'] as int,
        checkedEpisodeCnt: checkedEpisodeCnt,
      ));
    }
    return res;
  }

  static getAnimeCntPerTag() async {
    print("sql: getAnimeCntPerTag");
    var list = await _database.rawQuery('''
    select count(anime_id) as anime_cnt, tag.tag_name
    from tag left outer join anime -- sqlite只支持左外联结
        on anime.tag_name = tag.tag_name
    group by tag.tag_name -- 应该按照tag的tag_name分组
    order by tag.tag_order; -- 按照用户调整的顺序排序，否则会导致数量与实际不符
    ''');

    List<int> res = [];
    for (var item in list) {
      res.add(item['anime_cnt'] as int);
    }
    return res;
  }

  static Future<List<HistorySql>> getAllHistory() async {
    print("sql: getAllHistory");
    var list = await _database.rawQuery('''
      select date, history.anime_id, anime_name, episode_number
      from history inner join anime
          on history.anime_id = anime.anime_id
      order by date desc; -- 倒序
      ''');
    List<HistorySql> history = [];
    for (var item in list) {
      history.add(HistorySql(
          date: item['date'] as String,
          animeId: item['anime_id'] as int,
          animeName: item['anime_name'] as String,
          episodeNumber: item['episode_number'] as int));
    }
    return history;
  }
}
