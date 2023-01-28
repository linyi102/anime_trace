import 'package:flutter/material.dart';

import 'package:flutter_test_future/models/episode.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/pages/modules/note_edit.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/time_show_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:oktoast/oktoast.dart';

import '../../components/note_img_grid.dart';
import '../../dao/note_dao.dart';
import '../../models/anime.dart';
import '../../utils/theme_util.dart';
import '../modules/note_card.dart';

// 动漫详细页的评价列表页
class AnimeRateListPage extends StatefulWidget {
  final Anime anime;

  const AnimeRateListPage(this.anime, {Key? key}) : super(key: key);

  @override
  State<AnimeRateListPage> createState() => _AnimeRateListPageState();
}

class _AnimeRateListPageState extends State<AnimeRateListPage> {
  List<Note> notes = [];
  bool noteOk = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() {
    noteOk = false;
    NoteDao.getRateNotesByAnimeId(widget.anime.animeId).then((value) {
      notes = value;
      // 把所有评价笔记都指定anime，用于编辑评价笔记时显示
      for (var note in notes) {
        note.anime = widget.anime;
      }
      setState(() {
        noteOk = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);

    return Scaffold(
      appBar: AppBar(
          title: const Text("动漫评价",
              style: TextStyle(fontWeight: FontWeight.w600))),
      body: noteOk
          ? notes.isNotEmpty
              ? _buildRateNoteList()
              : Container()
          : Container(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createRateNote(context),
        backgroundColor: ThemeUtil.getPrimaryIconColor(),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  void _createRateNote(BuildContext context) {
    Log.info("添加评价");
    Note episodeNote =
        Note(anime: widget.anime, episode: Episode(0, 1), // 第0集作为评价
            relativeLocalImages: [], imgUrls: []);
    NoteDao.insertEpisodeNote(episodeNote).then((value) {
      // 获取到刚插入的笔记id，然后再进入笔记
      episodeNote.id = value;
      Navigator.push(context,
              MaterialPageRoute(builder: (context) => NoteEdit(episodeNote)))
          .then((value) {
        // 重新获取列表
        _loadData();
      });
    });
  }

  _buildRateNoteList() {
    return ListView.builder(
        padding: const EdgeInsetsDirectional.all(5),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          Log.info("$runtimeType: index=$index");
          Note note = notes[index];

          return NoteCard(
            note,
            removeNote: () {
              // 从notes中移除，并重绘整个页面
              setState(() {
                notes.removeAt(index);
              });
            },
            isRateNote: true,
          );
        });
  }
}
