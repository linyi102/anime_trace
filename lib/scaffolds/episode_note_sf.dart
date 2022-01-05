import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/episode_note.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';

class EpisodeNoteSF extends StatefulWidget {
  EpisodeNote episodeNote;
  EpisodeNoteSF(this.episodeNote, {Key? key}) : super(key: key);

  @override
  State<EpisodeNoteSF> createState() => _EpisodeNoteSFState();
}

class _EpisodeNoteSFState extends State<EpisodeNoteSF> {
  bool _loadOk = false;
  var noteContentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint("进入笔记${widget.episodeNote.episodeNoteId}");
    _loadData();
  }

  _loadData() async {
    Future(() {}).then((value) {
      setState(() {
        _loadOk = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        debugPrint("按返回键，返回episodeNote");
        Navigator.pop(context, widget.episodeNote);
        SqliteUtil.updateEpisodeNoteContentByNoteId(
            widget.episodeNote.episodeNoteId, widget.episodeNote.noteContent);
        debugPrint("返回true");
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                debugPrint("按返回按钮，返回episodeNote");
                Navigator.pop(context, widget.episodeNote);
                SqliteUtil.updateEpisodeNoteContentByNoteId(
                    widget.episodeNote.episodeNoteId,
                    widget.episodeNote.noteContent);
              },
              tooltip: "返回上一级",
              icon: const Icon(Icons.arrow_back_rounded)),
          foregroundColor: Colors.black,
          title: Text(
              "${widget.episodeNote.anime.animeName}>第 ${widget.episodeNote.episode.number} 集"),
        ),
        body: _loadOk
            ? TextField(
                controller: noteContentController
                  ..text = widget.episodeNote.noteContent,
                decoration: const InputDecoration(
                  hintText: "描述",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                ),
                style: const TextStyle(height: 1.5, fontSize: 16),
                onChanged: (value) {
                  widget.episodeNote.noteContent = value;
                },
              )
            : Container(),
      ),
    );
  }
}
