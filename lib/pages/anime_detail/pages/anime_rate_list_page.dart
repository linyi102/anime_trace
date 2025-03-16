import 'package:flutter/material.dart';
import 'package:animetrace/components/empty_data_hint.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/components/note/note_card.dart';
import 'package:animetrace/dao/note_dao.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/note.dart';
import 'package:animetrace/pages/modules/note_edit.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/widgets/common_scaffold_body.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

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
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  _loadData() async {
    noteOk = false;
    // await Future.delayed(const Duration(seconds: 1));
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
      appBar: AppBar(title: const Text("动漫评价")),
      body: CommonScaffoldBody(
          child: noteOk
              ? notes.isNotEmpty
                  ? _buildRateNoteList()
                  : emptyDataHint(msg: '还没有评价过。')
              : loadingWidget(context)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createRateNote(),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(MingCuteIcons.mgc_add_line, color: Colors.white),
      ),
    );
  }

  void _createRateNote() async {
    Log.info("添加评价");
    Note episodeNote = Note.createRateNote(widget.anime);
    episodeNote.id = await NoteDao.insertRateNote(widget.anime.animeId);
    final note = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => NoteEditPage(episodeNote)));
    if (note == null) return;
    notes.insert(0, note);
    if (mounted) setState(() {});
  }

  _buildRateNoteList() {
    return Scrollbar(
      controller: scrollController,
      child: SuperListView.builder(
          controller: scrollController,
          itemCount: notes.length,
          itemBuilder: (context, index) {
            Log.info("$runtimeType: index=$index");
            Note note = notes[index];

            return NoteCard(
              note,
              onDeleted: () {
                // 从notes中移除，并重绘整个页面
                setState(() {
                  notes.removeAt(index);
                });
              },
              isRateNote: true,
              showAnimeTile: true,
            );
          }),
    );
  }
}
