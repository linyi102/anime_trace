// // ignore_for_file: avoid_print
// import 'package:flutter_test_future/sql/anime_sql.dart';
// import 'package:flutter_test_future/sql/history_sql.dart';
// import 'package:flutter_test_future/utils/episode.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';

// class SqliteHelper {
//   // 单例模式
//   static SqliteHelper? _instance;

//   SqliteHelper._();

//   static SqliteHelper getInstance() {
//     return _instance ??= SqliteHelper._();
//   }

//   final sqlFileName = 'mydb1.db';
//   Database? _database;

//   get database async {
//     _database ??= await _initDatabase();
//     return _database;
//   }

//   _initDatabase() async {
//     String path = "${(await getExternalStorageDirectory())!.path}/$sqlFileName";
//     // String path = "${await getDatabasesPath()}/$sqlFileName";

//     print("👉path=$path");
//     await deleteDatabase(path); // 删除数据库，不知道为什么一定要加await
//     // 否则会出现Unhandled Exception: DatabaseException(database_closed 31)
//     return await openDatabase(
//       path,
//       onCreate: (Database db, int version) {
//         _createInitTable(db); // 只会在数据库创建时才会创建表，记得传入的是db，而不是databse
//         _insertInitData(db);
//       },
//       version: 1, // onCreate must be null if no version is specified
//     );
//   }

//   void _createInitTable(Database db) async {
//     await db.execute('''
//       CREATE TABLE tag (
//           tag_id   INTEGER PRIMARY KEY AUTOINCREMENT,
//           tag_name TEXT    NOT NULL
//       );
//       ''');
//     await db.execute('''
//       CREATE TABLE anime (
//           anime_id          INTEGER PRIMARY KEY AUTOINCREMENT,
//           anime_name        TEXT    NOT NULL,
//           anime_episode_cnt INTEGER NOT NULL,
//           tag_id            INTEGER,
//           FOREIGN KEY (
//               tag_id
//           )
//           REFERENCES tag (tag_id)
//       );
//       ''');
//     await db.execute('''
//       CREATE TABLE history (
//           history_id     INTEGER PRIMARY KEY AUTOINCREMENT,
//           date           TEXT,
//           anime_id       INTEGER NOT NULL,
//           episode_number INTEGER NOT NULL,
//           FOREIGN KEY (
//               anime_id
//           )
//           REFERENCES anime (anime_id)
//       );
//       ''');
//   }

//   void _insertInitData(Database db) async {
//     await db.rawInsert('''
//       insert into tag(tag_name)
//       values('拾'), ('途'), ('终'), ('搁'), ('弃');
//     ''');
//     for (int i = 0; i < 1; ++i) {
//       await db.rawInsert('''
//       insert into anime(anime_name, anime_episode_cnt, tag_id)
//       values('进击的巨人第一季', '24', 1),
//           ('JOJO的奇妙冒险第六季 石之海', '12', 1),
//           ('刀剑神域第一季', '24', 1),
//           ('进击的巨人第二季', '12', 1),
//           ('在下坂本，有何贵干？', '12', 3);
//     ''');
//     }
//     await db.rawInsert('''
//       insert into history(date, anime_id, episode_number)
//       values('2021-12-15 20:17:58', 2, 1),
//           ('2021-12-15 20:23:22', 2, 3),
//           ('2020-06-24 15:20:12', 1, 1),
//           ('2021-12-04 14:11:27', 4, 2),
//           ('2021-11-07 13:13:13', 3, 1),
//           ('2021-10-07 12:12:12', 5, 2);
//     ''');
//   }

//   getTagIdByTagName(String tagName) async {
//
//     var list = await _database.rawQuery('''
//     select tag_id from tag
//     where tag_name = '$tagName';
//     ''');
//     return list[0]['tag_id'].toString();
//   }

//   void modifyAnime(int animeId, AnimeSql newAnime) async {
//
//     int newTagId = int.parse(
//       await getTagIdByTagName(newAnime.tagName),
//     ); // 一定要await

//     // int count =
//     await _database.rawUpdate('''
//     update anime
//     set anime_name = '${newAnime.animeName}',
//         anime_episode_cnt = ${newAnime.animeEpisodeCnt},
//         tag_id = $newTagId
//     where anime_id = $animeId;
//     ''');
//     // print("count=$count");
//   }

//   void insertAnime(AnimeSql anime) async {
//
//     // 先根据tag_name获取到tag_id
//     int tagId = (await _database.rawQuery('''
//     select tag_id from tag
//     where tag_name = '${anime.tagName}';
//     '''))[0]['tag_id'] as int;
//     // 解释：返回List<Map<String, Object?>>，[0]代表取第一个元素，['tag_id']通过key得到value。

//     await _database.rawInsert('''
//     insert into anime(anime_name, anime_episode_cnt, tag_id)
//     values('${anime.animeName}', '${anime.animeEpisodeCnt}', $tagId);
//     ''');
//   }

//   void insertHistoryItem(int animeId, int episodeNumber) async {
//
//     String date = DateTime.now().toString();

//     await _database.rawInsert('''
//     insert into history(date, anime_id, episode_number)
//     values('$date', $animeId, $episodeNumber);
//     ''');
//   }

//   void removeHistoryItem(String? date) async {
//
//     await _database.rawDelete('''
//     delete from history
//     where date = '$date';
//     ''');
//   }

//   getAnimeByAnimeId(int animeId) async {
//
//     var list = await _database.rawQuery('''
//     select anime_name, anime_episode_cnt, tag_name
//     from anime inner join tag
//         on anime_id = $animeId and anime.tag_id = tag.tag_id;
//     ''');
//     AnimeSql anime = AnimeSql(
//         animeName: list[0]['anime_name'] as String,
//         animeEpisodeCnt: list[0]['anime_episode_cnt'] as int,
//         tagName: list[0]['tag_name'] as String);
//     return anime;
//   }

//   getTagNameByAnimeId(int animeId) async {
//
//     var list = await _database.rawQuery('''
//     select tag_name
//     from anime inner join tag
//         on anime_id = $animeId and anime.tag_id = tag.tag_id;
//     ''');
//     return list[0]['tag_name'];
//   }

//   getAnimeEpisodeHistoryById(int animeId) async {
//
//     AnimeSql anime = await getAnimeByAnimeId(animeId);
//     int animeEpisodeCnt = anime.animeEpisodeCnt;

//     var list = await _database.rawQuery('''
//     select date, episode_number
//     from anime inner join history
//         on anime.anime_id = $animeId and anime.anime_id = history.anime_id;
//     ''');
//     // print("查询结果：$list");
//     List<Episode> episodes = [];
//     for (int episodeNumber = 1;
//         episodeNumber <= animeEpisodeCnt;
//         ++episodeNumber) {
//       episodes.add(Episode(episodeNumber));
//     }
//     // 遍历查询结果，每个元素都是一个键值对(列名-值)
//     for (var element in list) {
//       int episodeNumber = element['episode_number'] as int;
//       episodes[episodeNumber - 1].dateTime = element['date'] as String;
//     }
//     return episodes;
//   }

//   getAllAnimeBytag(String tag) async {
//     print("sql: getAllAnimeBytag");
//   // 必须要await，不能直接使用！

//     var list = await _database.rawQuery('''
//     select anime_id, anime_name, anime_episode_cnt
//     from anime inner join tag
//         on tag.tag_name = '$tag' and anime.tag_id = tag.tag_id
//     order by anime_id desc;
//     // limit 100 offset 0;
//     '''); // 按anime_id倒序，保证最新添加的动漫在最上面

//     List<AnimeSql> res = [];
//     for (var element in list) {
//       var checkedEpisodeCntList = await _database.rawQuery('''
//       select count(anime.anime_id) cnt
//       from anime inner join history
//           on anime.anime_id = ${element['anime_id']} and anime.anime_id = history.anime_id;
//       ''');
//       int checkedEpisodeCnt = checkedEpisodeCntList[0]["cnt"] as int;

//       res.add(AnimeSql(
//         animeId: element['anime_id'] as int, // 进入详细页面后需要该id
//         animeName: element['anime_name'] as String,
//         animeEpisodeCnt: element['anime_episode_cnt'] as int,
//         checkedEpisodeCnt: checkedEpisodeCnt,
//       ));
//     }
//     return res;
//   }

//   getAnimeCntPerTag() async {
//
//     var list = await _database.rawQuery('''
//     select count(anime_id) as anime_cnt, tag.tag_name
//     from tag left outer join anime -- sqlite只支持左外联结
//         on anime.tag_id = tag.tag_id
//     group by tag.tag_id; -- 应该按照tag的tag_id分组
//     ''');

//     List<int> res = [];
//     for (var item in list) {
//       res.add(item['anime_cnt'] as int);
//     }
//     return res;
//   }

//   Future<List<HistorySql>> getAllHistory() async {
//     print("sql: getAllHistory");
//
//     var list = await _database.rawQuery('''
//       select date, history.anime_id, anime_name, episode_number
//       from history inner join anime
//           on history.anime_id = anime.anime_id
//       order by date desc; -- 倒序
//       ''');
//     List<HistorySql> history = [];
//     for (var item in list) {
//       history.add(HistorySql(
//           date: item['date'] as String,
//           animeId: item['anime_id'] as int,
//           animeName: item['anime_name'] as String,
//           episodeNumber: item['episode_number'] as int));
//     }
//     return history;
//   }
// }
// ignore_for_file: avoid_print
import 'package:flutter_test_future/sql/anime_sql.dart';
import 'package:flutter_test_future/sql/history_sql.dart';
import 'package:flutter_test_future/utils/episode.dart';
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

  static const sqlFileName = 'mydb1.db';
  static late Database _database;

  static _initDatabase() async {
    String path = "${(await getExternalStorageDirectory())!.path}/$sqlFileName";
    // String path = "${await getDatabasesPath()}/$sqlFileName";

    print("👉path=$path");
    // await deleteDatabase(path); // 删除数据库，不知道为什么一定要加await
    // 否则会出现Unhandled Exception: DatabaseException(database_closed 31)
    return await openDatabase(
      path,
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
          tag_id   INTEGER PRIMARY KEY AUTOINCREMENT,
          tag_name TEXT    NOT NULL
      );
      ''');
    await db.execute('''
      CREATE TABLE anime (
          anime_id          INTEGER PRIMARY KEY AUTOINCREMENT,
          anime_name        TEXT    NOT NULL,
          anime_episode_cnt INTEGER NOT NULL,
          tag_id            INTEGER,
          FOREIGN KEY (
              tag_id
          )
          REFERENCES tag (tag_id) 
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
      insert into tag(tag_name)
      values('拾'), ('途'), ('终'), ('搁'), ('弃');
    ''');
    for (int i = 0; i < 1; ++i) {
      await db.rawInsert('''
      insert into anime(anime_name, anime_episode_cnt, tag_id)
      values('进击的巨人第一季', '24', 1),
          ('JOJO的奇妙冒险第六季 石之海', '12', 1),
          ('刀剑神域第一季', '24', 1),
          ('进击的巨人第二季', '12', 1),
          ('在下坂本，有何贵干？', '12', 3);
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

  static getTagIdByTagName(String tagName) async {
    var list = await _database.rawQuery('''
    select tag_id from tag
    where tag_name = '$tagName';
    ''');
    return list[0]['tag_id'].toString();
  }

  static void modifyAnime(int animeId, AnimeSql newAnime) async {
    int newTagId = int.parse(
      await getTagIdByTagName(newAnime.tagName),
    ); // 一定要await

    // int count =
    await _database.rawUpdate('''
    update anime
    set anime_name = '${newAnime.animeName}',
        anime_episode_cnt = ${newAnime.animeEpisodeCnt},
        tag_id = $newTagId
    where anime_id = $animeId;
    ''');
    // print("count=$count");
  }

  static void insertAnime(AnimeSql anime) async {
    // 先根据tag_name获取到tag_id
    int tagId = (await _database.rawQuery('''
    select tag_id from tag
    where tag_name = '${anime.tagName}';
    '''))[0]['tag_id'] as int;
    // 解释：返回List<Map<String, Object?>>，[0]代表取第一个元素，['tag_id']通过key得到value。

    await _database.rawInsert('''
    insert into anime(anime_name, anime_episode_cnt, tag_id)
    values('${anime.animeName}', '${anime.animeEpisodeCnt}', $tagId);
    ''');
  }

  static void insertHistoryItem(int animeId, int episodeNumber) async {
    String date = DateTime.now().toString();

    await _database.rawInsert('''
    insert into history(date, anime_id, episode_number)
    values('$date', $animeId, $episodeNumber);
    ''');
  }

  static void removeHistoryItem(String? date) async {
    await _database.rawDelete('''
    delete from history
    where date = '$date';
    ''');
  }

  static getAnimeByAnimeId(int animeId) async {
    var list = await _database.rawQuery('''
    select anime_name, anime_episode_cnt, tag_name
    from anime inner join tag
        on anime_id = $animeId and anime.tag_id = tag.tag_id;
    ''');
    AnimeSql anime = AnimeSql(
        animeName: list[0]['anime_name'] as String,
        animeEpisodeCnt: list[0]['anime_episode_cnt'] as int,
        tagName: list[0]['tag_name'] as String);
    return anime;
  }

  static getTagNameByAnimeId(int animeId) async {
    var list = await _database.rawQuery('''
    select tag_name
    from anime inner join tag
        on anime_id = $animeId and anime.tag_id = tag.tag_id;
    ''');
    return list[0]['tag_name'];
  }

  static getAnimeEpisodeHistoryById(int animeId) async {
    AnimeSql anime = await getAnimeByAnimeId(animeId);
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

  static getAllAnimeBytag(String tag) async {
    print("sql: getAllAnimeBytag"); // 必须要await，不能直接使用！

    var list = await _database.rawQuery('''
    select anime_id, anime_name, anime_episode_cnt
    from anime inner join tag
        on tag.tag_name = '$tag' and anime.tag_id = tag.tag_id
    order by anime_id desc;
    // limit 100 offset 0;
    '''); // 按anime_id倒序，保证最新添加的动漫在最上面

    List<AnimeSql> res = [];
    for (var element in list) {
      var checkedEpisodeCntList = await _database.rawQuery('''
      select count(anime.anime_id) cnt
      from anime inner join history
          on anime.anime_id = ${element['anime_id']} and anime.anime_id = history.anime_id;
      ''');
      int checkedEpisodeCnt = checkedEpisodeCntList[0]["cnt"] as int;

      res.add(AnimeSql(
        animeId: element['anime_id'] as int, // 进入详细页面后需要该id
        animeName: element['anime_name'] as String,
        animeEpisodeCnt: element['anime_episode_cnt'] as int,
        checkedEpisodeCnt: checkedEpisodeCnt,
      ));
    }
    return res;
  }

  static getAnimeCntPerTag() async {
    var list = await _database.rawQuery('''
    select count(anime_id) as anime_cnt, tag.tag_name
    from tag left outer join anime -- sqlite只支持左外联结
        on anime.tag_id = tag.tag_id
    group by tag.tag_id; -- 应该按照tag的tag_id分组
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
