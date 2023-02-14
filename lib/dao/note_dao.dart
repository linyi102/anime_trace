import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../models/anime.dart';
import '../models/episode.dart';
import '../models/note_filter.dart';
import '../models/relative_local_image.dart';
import '../utils/escape_util.dart';

class NoteDao {
  static var database = SqliteUtil.database;

  // map转为对象
  static Future<Note> row2bean(Map row, {bool searchAnime = false}) async {
    // 查询这个笔记的图片
    int noteId = row['note_id'] as int;
    List<RelativeLocalImage> relativeLocalImages =
        await getRelativeLocalImgsByNoteId(noteId);
    Anime anime = searchAnime
        ? await SqliteUtil.getAnimeByAnimeId(
            row['anime_id']) // 查看所有评价列表时，每个笔记需要知道动漫信息
        : Anime(animeName: "无名", animeEpisodeCnt: 0); // 动漫详细页中的评价列表不需要再查询动漫

    return Note(
        id: noteId,
        anime: anime,
        episode: Episode(0, 1),
        noteContent: row['note_content'] as String,
        createTime: row['create_time'] as String? ?? "",
        updateTime: row['update_time'] as String? ?? "",
        relativeLocalImages: relativeLocalImages,
        imgUrls: []);
  }

  // 所有评价列表。分页
  static Future<List<Note>> getRateNotes(
      {required PageParams pageParams, required NoteFilter noteFilter}) async {
    Log.info("sql: getRateNotes");
    List<Note> rateNotes = [];
    List<Map<String, Object?>> list = await database.rawQuery('''
    select anime_id, note_id, note_content, create_time, update_time from episode_note
    where episode_number = 0 order by create_time desc limit ${pageParams.pageSize} offset ${pageParams.getOffset()};
    ''');
    for (Map row in list) {
      rateNotes.add(await row2bean(row, searchAnime: true));
    }

    return rateNotes;
  }

  // 获取某个动漫的笔记数量
  static Future<int> getRateNoteCountByAnimeId(int animeId) async {
    Log.info("sql: getRateNoteCountByAnimeId");
    List<Map<String, Object?>> list = await database.rawQuery('''
      select count(*) cnt from episode_note
      where anime_id = $animeId and episode_number = 0;
    ''');
    return list[0]["cnt"] as int;
  }

  // 获取某个动漫的所有笔记
  static Future<List<Note>> getRateNotesByAnimeId(int animeId) async {
    Log.info("sql: getRateNotesByAnimeId");
    List<Note> rateNotes = [];
    List<Map<String, Object?>> list = await database.rawQuery('''
      select note_id, note_content, create_time, update_time from episode_note
      where anime_id = $animeId and episode_number = 0 order by note_id desc;
    ''');

    // 遍历每个评价笔记
    for (Map row in list) {
      Note rateNote = await row2bean(row);
      rateNote.anime.animeId =
          animeId; // 用于动漫详细页的评价tab进入评价笔记编辑页时根据animeId,episdoeNumber,review获取评价内容
      rateNotes.add(rateNote);
    }

    return rateNotes;
  }

  // -- 默认升序时，null会排在数字前面
  // select * from image
  // order by order_idx, image_id limit 10;
  //
  // -- 解决方法
  // -- 解释：如果order_idx为null，则设置为1，其余设置为0(这样就能保证为null的排在后面)，对于相等的0，则按照order_idx排序
  // select * from image
  // order by case when order_idx is null then 1 else 0 end, order_idx, image_id limit 10;
  static Future<List<RelativeLocalImage>> getRelativeLocalImgsByNoteId(
      int noteId) async {
    var db = SqliteUtil.database;
    // 还是不行
    // 假设图片id都为null，此时把第9个图片移到第2个，保存到数据库后，第1个图片的order_idx仍为null，那么下次这个第1张图片就会跑到后面，而不会是第1张
    // var lm = await db.rawQuery('''
    // select image_id, image_local_path from image
    // where note_id = $noteId
    // order by case when order_idx is null then 1 else 0 end, order_idx, note_id; -- 先按照指定顺序升序，如果还没有顺序，则按照id升序
    // ''');
    // 还是每次把所有图片又重新设置下标吧
    var lm = await db.rawQuery('''
    select image_id, image_local_path from image
    where note_id = $noteId
    order by order_idx, note_id; -- 先按照指定顺序升序，如果还没有顺序，则按照id升序
    ''');
    List<RelativeLocalImage> relativeLocalImages = [];
    for (var item in lm) {
      relativeLocalImages.add(RelativeLocalImage(
          item['image_id'] as int, item['image_local_path'] as String));
    }
    return relativeLocalImages;
  }

  static updateEpisodeNoteContentByNoteId(
      int noteId, String noteContent) async {
    Log.info("sql: updateEpisodeNoteContent($noteId)");
    // Log.info("sql: updateEpisodeNoteContent($noteId, $noteContent)");
    noteContent = EscapeUtil.escapeStr(noteContent);
    database.rawUpdate('''
    update episode_note
    set note_content = '$noteContent'
    where note_id = $noteId;
    ''');
  }

  static Future<bool> existNoteId(int noteId) async {
    var list = await database.rawQuery('''
    select note_id from episode_note
    where note_id = $noteId;
    ''');
    if (list.isEmpty) {
      return false;
    }
    return true;
  }

  static Note escapeEpisodeNote(Note episodeNote) {
    episodeNote.noteContent = EscapeUtil.escapeStr(episodeNote.noteContent);
    return episodeNote;
  }

  static Future<int> insertEpisodeNote(Note episodeNote) async {
    Log.info(
        "sql: insertEpisodeNote(animeId=${episodeNote.anime.animeId}, episodeNumber=${episodeNote.episode.number}, reviewNumber=${episodeNote.episode.reviewNumber})");
    episodeNote = escapeEpisodeNote(episodeNote);
    String createTime = DateTime.now().toString();

    return await database.rawInsert('''
    insert into episode_note (anime_id, episode_number, review_number, note_content, create_time)
    values (${episodeNote.anime.animeId}, ${episodeNote.episode.number}, ${episodeNote.episode.reviewNumber}, '', '$createTime'); -- 空内容
    ''');
  }

  static Future<Note> getNoteContentAndImagesByNoteId(int noteId) async {
    Log.info("getNoteByNoteId(noteId=$noteId)");
    var lm1 = await database.rawQuery('''
      select anime_id, note_id, episode_number, review_number, note_content from episode_note
      where note_id = $noteId;
      ''');
    Note note = Note(
        id: 0,
        anime: Anime(animeName: "无名"),
        episode: Episode(0, 1),
        relativeLocalImages: [],
        imgUrls: []);
    if (lm1.isNotEmpty) {
      note.noteContent = lm1[0]['note_content'] as String;
      note.id = noteId;
      // note.anime =
      //     await SqliteUtil.getAnimeByAnimeId(lm1[0]['anime_id'] as int);
      // note.anime.reviewNumber = lm1[0]['review_number'] as int;
      note.relativeLocalImages = await getRelativeLocalImgsByNoteId(noteId);
    }
    return note;
  }

  static Future<Note> getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(
      Note episodeNote) async {
    // Log.info(
    //     "sql: getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(episodeNumber=${episodeNote.episode.number}, review_number=${episodeNote.episode.reviewNumber})");
    // 查询内容
    var lm1 = await database.rawQuery('''
      select note_id, note_content from episode_note
      where anime_id = ${episodeNote.anime.animeId} and episode_number = ${episodeNote.episode.number} and review_number = ${episodeNote.episode.reviewNumber};
      ''');
    if (lm1.isEmpty) {
      // 如果没有则插入笔记(为了兼容之前完成某集后不会插入空笔记)
      episodeNote.id = await insertEpisodeNote(episodeNote);
    } else {
      episodeNote.id = lm1[0]['note_id'] as int;
      // 获取笔记内容
      episodeNote.noteContent = lm1[0]['note_content'] as String;
    }
    // Log.info("笔记${episodeNote.episodeNoteId}内容：${episodeNote.noteContent}");
    // 查询图片
    episodeNote.relativeLocalImages =
        await getRelativeLocalImgsByNoteId(episodeNote.id);
    episodeNote = restoreEscapeEpisodeNote(episodeNote);
    return episodeNote;
  }

  static Future<List<Note>> getAllNotesByTableHistory() async {
    Log.info("sql: getAllNotesByTableHistory");
    List<Note> episodeNotes = [];
    // 根据history表中的anime_id和episode_number来获取相应的笔记，并按时间倒序排序
    var lm1 = await database.rawQuery('''
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
      Note episodeNote = Note(
          anime: anime, episode: episode, relativeLocalImages: [], imgUrls: []);
      episodeNote =
          await getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(
              episodeNote);
      // Log.info(episodeNote);
      episodeNote.relativeLocalImages =
          await getRelativeLocalImgsByNoteId(episodeNote.id);
      episodeNotes.add(restoreEscapeEpisodeNote(episodeNote));
    }
    return episodeNotes;
  }

  //↓优化
  static Future<List<Note>> getAllNotesByTableNoteAndKeyword(
      int offset, int number, NoteFilter noteFilter) async {
    Log.info("sql: getAllNotesByTableNote");
    List<Note> episodeNotes = [];
    // 根据笔记中的动漫id和集数number(还有回顾号review_number)，即可获取到完成时间，根据动漫id，获取动漫封面
    // 因为pageSize个笔记中有些笔记没有内容和图片，在之后会过滤掉，所以并不会得到pageSize个笔记，从而导致滑动到最下面也不够pageSize个，而无法再次请求
    // var lm1 = await _database.rawQuery('''
    // select episode_note.note_id, episode_note.note_content, episode_note.anime_id, episode_note.episode_number, history.date, anime.anime_name, anime.anime_cover_url, episode_note.review_number
    // from episode_note, anime, history
    // where episode_note.anime_id = anime.anime_id and episode_note.anime_id = history.anime_id and episode_note.episode_number = history.episode_number and episode_note.review_number = history.review_number
    // order by history.date desc
    // limit $number offset $offset;
    // ''');

    // 优化：不会筛选出笔记内容和图片都没有的行
    String likeAnimeNameSql = "";
    String likeNoteContentSql = "";
    if (noteFilter.animeNameKeyword.isNotEmpty) {
      likeAnimeNameSql =
          "and anime.anime_name like '%${EscapeUtil.escapeStr(noteFilter.animeNameKeyword)}%'";
    }
    if (noteFilter.noteContentKeyword.isNotEmpty) {
      likeNoteContentSql =
          "and note_content like '%${EscapeUtil.escapeStr(noteFilter.noteContentKeyword)}%'";
    }
    String sql = '''
      select anime.*, history.date, episode_note.episode_number, episode_note.review_number, episode_note.note_id, episode_note.note_content
      from history, episode_note, anime
      where history.anime_id = episode_note.anime_id and history.episode_number = episode_note.episode_number
          and history.review_number = episode_note.review_number
          and anime.anime_id = history.anime_id
          $likeAnimeNameSql
          and episode_note.note_id in(
              select distinct episode_note.note_id
              from episode_note inner join image on episode_note.note_id = image.note_id $likeNoteContentSql
              union
              select episode_note.note_id
              from episode_note where note_content is not null and length(note_content) > 0 $likeNoteContentSql
          )
      order by history.date desc
      limit $number offset $offset;
    ''';
    var lm1 = await database.rawQuery(sql);
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
      Note episodeNote = Note(
          id: item['note_id'] as int,
          // 忘记设置了，导致都是进入笔记0
          anime: anime,
          episode: episode,
          noteContent: item['note_content'] as String,
          relativeLocalImages: relativeLocalImages,
          imgUrls: []);
      // // 如果没有图片，且笔记内容为空，则不添加。会导致无法显示分页查询
      // if (episodeNote.relativeLocalImages.isEmpty &&
      //     episodeNote.noteContent.isEmpty) continue;
      episodeNotes.add(restoreEscapeEpisodeNote(episodeNote));
    }
    return episodeNotes;
  }

  static Note restoreEscapeEpisodeNote(Note episodeNote) {
    episodeNote.noteContent =
        EscapeUtil.restoreEscapeStr(episodeNote.noteContent);
    return episodeNote;
  }

  // 删除评价笔记/集笔记
  // 先删除与笔记相关的图片，再删除该笔记(id唯一，不用在意reviewNumber，而且删除集笔记后当进入详情页会自动创建空笔记)
  static Future<bool> deleteNoteById(int noteId) async {
    int num = await database.rawDelete('''
    delete from image
    where note_id = $noteId;
    ''');
    Log.info("删除了$num个与该笔记相关的图片");
    num = await database.rawDelete('''
    delete from episode_note
    where note_id = $noteId;
    ''');
    Log.info("删除了$num条笔记(id=$noteId)");
    return true;
  }
}
