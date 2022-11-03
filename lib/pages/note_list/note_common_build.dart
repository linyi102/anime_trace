import 'package:flutter/material.dart';

import '../../animation/fade_route.dart';
import '../../components/anime_list_cover.dart';
import '../../models/anime.dart';
import '../../models/note.dart';
import '../../utils/theme_util.dart';
import '../anime_detail/anime_detail.dart';
import '../modules/note_edit.dart';

class NoteCommonBuild {
  static buildNote({required Note note}) {
    if (note.noteContent.isEmpty) return Container();
    return ListTile(
      title: Text(
        note.noteContent,
        maxLines: 10,
        overflow: TextOverflow.ellipsis,
        style: ThemeUtil.getNoteTextStyle(),
      ),
      style: ListTileStyle.drawer,
    );
  }

  static buildAnimeListTile(
      {required setState, required BuildContext context, required Note note}) {
    bool isRateNote = note.episode.number == 0;

    return ListTile(
      leading: GestureDetector(
        onTap: () {
          _enterAnimeDetail(context: context, anime: note.anime);
        },
        child: AnimeListCover(
          note.anime,
          showReviewNumber: true,
          reviewNumber: note.episode.reviewNumber,
        ),
      ),
      // trailing: IconButton(
      //     onPressed: () {
      //       Navigator.of(context).push(
      //         FadeRoute(builder: (context) {
      //           return NoteEdit(note);
      //         }),
      //       ).then((value) {
      //         note = value; // 更新修改
      //         setState(() {});
      //       });
      //     },
      //     // navigate_next
      //     icon: Icon(Icons.edit_note, color: ThemeUtil.getCommonIconColor())),
      title: GestureDetector(
        onTap: () => _enterAnimeDetail(context: context, anime: note.anime),
        child: Text(
          note.anime.animeName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textScaleFactor: ThemeUtil.smallScaleFactor,
          // textAlign: TextAlign.right,
        ),
      ),
      subtitle: isRateNote
          ? null
          : GestureDetector(
              onTap: () =>
                  _enterAnimeDetail(context: context, anime: note.anime),
              child: Text(
                  "第 ${note.episode.number} 集 ${note.episode.getDate()}",
                  textScaleFactor: ThemeUtil.tinyScaleFactor)),
    );
  }

  static _enterAnimeDetail(
      {required BuildContext context, required Anime anime}) {
    Navigator.of(context)
        .push(
      FadeRoute(
        transitionDuration: const Duration(milliseconds: 200),
        builder: (context) {
          return AnimeDetailPlus(anime);
        },
      ),
    )
        .then((value) {
      // // _loadData(); // 会导致重新请求数据从而覆盖episodeNotes，而返回时应该要恢复到原来的位置
      // Anime anime = value;
      // // 如果animeId为0，说明进入动漫详细页后删除了动漫，需要从笔记列表中删除相关笔记
      // if (!anime.isCollected()) {
      //   episodeNotes
      //       .removeWhere((element) => element.anime.animeId == anime.animeId);
      // }
      // setState(() {});
    });
  }
}
