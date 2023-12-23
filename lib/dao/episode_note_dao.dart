import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';

class EpisodeNoteDao {
  /// 获取最近创建笔记的动漫
  static getAnimesRecentlyCreateNote() async {
    final rows = await SqliteUtil.database.rawQuery('''
      select distinct episode_note.anime_id from episode_note
      order by episode_note.note_id desc
    ''');
    List<Anime> animes = [];

    for (final row in rows) {
      int? animeId = row['anime_id'] as int?;
      if (animeId == null) continue;

      animes.add(await SqliteUtil.getAnimeByAnimeId(animeId));
    }

    return animes;
  }
}
