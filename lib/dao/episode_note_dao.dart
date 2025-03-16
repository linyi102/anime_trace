import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/enum/note_type.dart';
import 'package:animetrace/utils/sqlite_util.dart';

class EpisodeNoteDao {
  /// 获取最近创建笔记的动漫
  static getAnimesRecentlyCreateNote({NoteType? noteType}) async {
    String whereSql = '';
    switch (noteType) {
      case NoteType.episode:
        whereSql = 'where episode_number > 0';
        break;
      case NoteType.rate:
        whereSql = 'where episode_number = 0';
        break;
      default:
    }

    final rows = await SqliteUtil.database.rawQuery('''
      select distinct episode_note.anime_id from episode_note
      $whereSql
      order by episode_note.note_id desc
    ''');
    List<Anime> animes = [];

    for (final row in rows) {
      int? animeId = row['anime_id'] as int?;
      if (animeId == null) continue;

      final anime = await SqliteUtil.getAnimeByAnimeId(animeId);
      if (anime.isCollected()) {
        animes.add(anime);
      }
    }

    return animes;
  }
}
