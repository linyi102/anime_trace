// ignore_for_file: avoid_print
import 'package:flutter_test_future/sql/anime_sql.dart';
import 'package:flutter_test_future/utils/episode.dart';
import 'package:sqflite/sqflite.dart';

class SqliteHelper {
  // 单例模式
  static SqliteHelper? _single;

  SqliteHelper._();

  static SqliteHelper getInstance() {
    return _single ??= SqliteHelper._();
  }

  final sqlFileName = 'mydb1.db';
  late Database database;

  void open() async {
    String path = "${await getDatabasesPath()}/$sqlFileName";
    database = await openDatabase(path);
    // ''' 多行字符串 '''
    await database.execute('''
      DROP TABLE tag;
      ''');
    await database.execute('''
      DROP TABLE anime;
      ''');
    await database.execute('''
      DROP TABLE history;
      ''');
    _createTable();
    _insertInitData();
  }

  void _createTable() async {
    await database.execute('''
      CREATE TABLE tag (
          tag_id   INTEGER PRIMARY KEY AUTOINCREMENT,
          tag_name TEXT    NOT NULL
      );
      ''');
    await database.execute('''
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
    await database.execute('''
      CREATE TABLE history (
          date           TEXT    PRIMARY KEY,
          anime_id       INTEGER NOT NULL,
          episode_number INTEGER NOT NULL,
          FOREIGN KEY (
              anime_id
          )
          REFERENCES anime (anime_id) 
      );
      ''');
  }

  void _insertInitData() async {
    await database.rawInsert('''
      insert into tag(tag_name)
      values('拾'), ('途'), ('终'), ('搁'), ('弃');
    ''');
    await database.rawInsert('''
      insert into anime(anime_name, anime_episode_cnt, tag_id)
      values('进击的巨人第一季', '24', 1),
          ('JOJO的奇妙冒险第六季 石之海', '12', 1),
          ('刀剑神域第一季', '24', 1),
          ('进击的巨人第二季', '12', 1),
          ('在下坂本，有何贵干？', '12', 3);
    ''');
    await database.rawInsert('''
      insert into history(date, anime_id, episode_number)
      values('2021-12-15 20:17:58', 2, 1),
          ('2021-12-15 20:23:22', 2, 3),
          ('2020-06-24 15:20:12', 1, 1),
          ('2021-12-04 14:11:27', 4, 2),
          ('2021-11-07 13:13:13', 3, 1),
          ('2021-10-07 12:12:12', 5, 2);
    ''');
  }

  getTagIdByTagName(String tagName) async {
    var list = await database.rawQuery('''
    select tag_id from tag
    where tag_name = '$tagName';
    ''');
    return list[0]['tag_id'].toString();
  }

  void modifyAnime(int animeId, AnimeSql newAnime) async {
    int newTagId = int.parse(
      await getTagIdByTagName(newAnime.tagName),
    ); // 一定要await

    // int count =
    await database.rawUpdate('''
    update anime
    set anime_name = '${newAnime.animeName}',
        anime_episode_cnt = ${newAnime.animeEpisodeCnt},
        tag_id = $newTagId
    where anime_id = $animeId;
    ''');
    // print("count=$count");
  }

  void insertAnime(AnimeSql anime) async {
    // 先根据tag_name获取到tag_id
    int tagId = (await database.rawQuery('''
    select tag_id from tag
    where tag_name = '${anime.tagName}';
    '''))[0]['tag_id'] as int;
    // 解释：返回List<Map<String, Object?>>，[0]代表取第一个元素，['tag_id']通过key得到value。

    await database.rawInsert('''
    insert into anime(anime_name, anime_episode_cnt, tag_id)
    values('${anime.animeName}', '${anime.animeEpisodeCnt}', $tagId);
    ''');
  }

  void insertHistoryItem(int animeId, int episodeNumber) async {
    String date = DateTime.now().toString();

    await database.rawInsert('''
    insert into history(date, anime_id, episode_number)
    values('$date', $animeId, $episodeNumber);
    ''');
  }

  void removeHistoryItem(String? date) async {
    await database.rawDelete('''
    delete from history
    where date = '$date';
    ''');
  }

  getAnimeById(int animeId) async {
    var list = await database.rawQuery('''
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

  getTagNameByAnimeId(int animeId) async {
    var list = await database.rawQuery('''
    select tag_name
    from anime inner join tag
        on anime_id = $animeId and anime.tag_id = tag.tag_id;
    ''');
    return list[0]['tag_name'];
  }

  getAnimeEpisodeHistoryById(int animeId) async {
    AnimeSql anime = await getAnimeById(animeId);
    int animeEpisodeCnt = anime.animeEpisodeCnt;

    var list = await database.rawQuery('''
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

  getAllAnimeBytag(String tag) async {
    var list = await database.rawQuery('''
    select anime_id, anime_name, anime_episode_cnt
    from anime inner join tag
      on tag.tag_name = '$tag' and anime.tag_id = tag.tag_id;
    ''');

    List<AnimeSql> res = [];
    for (var element in list) {
      var checkedEpisodeCntList = await database.rawQuery('''
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

  getAllTag() async {
    var list = await database.rawQuery('''
    select tag_name from tag;
    ''');
    // 得到的是一个数组，每个元素是一个Map：List<Map<String, Object?>>
    // 需要通过key获取到对应的值，得到List<Object?>
    var res = list.map((e) {
      return e['tag_name'];
    });
    // toList： (...)-->[...]
    // cast<String>：List<Object?>-->List<String>
    // return res.toList().cast<String>();
    return res.toList().cast<String>();
  }

  getAllAnime() async {
    var list = await database.rawQuery('''
    select anime_name from anime;
    ''');
    var res = list.map((e) {
      return e['anime_name'];
    });
    return res.toList().cast<String>();
  }

  getAllHistory() async {
    var list = await database.rawQuery('''
      select date, anime_name, episode_number
      from history;
      ''');
    var res = list.map((e) {
      return e['date'];
    });
    return res.toList().cast<String>();
  }
}
