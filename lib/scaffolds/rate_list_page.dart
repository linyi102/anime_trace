import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/episode.dart';
import 'package:flutter_test_future/classes/episode_note.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/note_edit.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/time_show_util.dart';

import '../classes/anime.dart';
import '../components/anime_list_cover.dart';
import '../components/image_grid_view.dart';
import '../utils/theme_util.dart';

class RateListPage extends StatefulWidget {
  final Anime anime;

  const RateListPage(this.anime, {Key? key}) : super(key: key);

  @override
  State<RateListPage> createState() => _RateListPageState();
}

class _RateListPageState extends State<RateListPage> {
  late Anime anime;
  List<EpisodeNote> notes = [];
  bool noteOk = false;

  @override
  void initState() {
    super.initState();
    anime = widget.anime;
    _loadData();
  }

  _loadData() {
    noteOk = false;
    SqliteUtil.getRateNotesByAnimeId(anime.animeId).then((value) {
      notes = value;
      setState(() {
        noteOk = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "动漫评价",
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              debugPrint("添加评价");
              EpisodeNote episodeNote =
                  EpisodeNote(anime: anime, episode: Episode(0, 1), // 第0集作为评价
                      relativeLocalImages: [], imgUrls: []);
              SqliteUtil.insertEpisodeNote(episodeNote).then((value) {
                // 获取到刚插入的笔记id，然后再进入笔记
                episodeNote.episodeNoteId = value;
                Navigator.push(context,
                        FadeRoute(builder: (context) => NoteEdit(episodeNote)))
                    .then((value) {
                  // 重新获取列表
                  _loadData();
                });
              });
            },
            child: const Icon(Icons.edit)),
        body: Column(
          children: [
            ListTile(
              style: ListTileStyle.drawer,
              leading: AnimeListCover(anime),
              title: Text(
                widget.anime.animeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Scrollbar(
                child: noteOk
                    ? notes.isEmpty
                        ? emptyDataHint("什么都没有")
                        : ListView(
                            children: _buildRateNoteList(),
                          )
                    : Container(),
              ),
            ),
          ],
        ));
  }

  _buildRateNoteList() {
    List<Widget> list = [];
    debugPrint("渲染1次笔记列表"); // TODO：多次渲染

    for (EpisodeNote note in notes) {
      list.add(Container(
        padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
        child: MaterialButton(
          elevation: 0,
          padding: const EdgeInsets.all(0),
          color: ThemeUtil.getNoteCardColor(),
          onPressed: () {
            Navigator.of(context).push(
              FadeRoute(
                builder: (context) {
                  return NoteEdit(note);
                },
              ),
            ).then((value) {
              // 重新获取列表
              _loadData();
            });
          },
          child: Flex(
            direction: Axis.vertical,
            children: [
              // 笔记内容
              _buildNoteContent(note),
              // 笔记图片
              ImageGridView(relativeLocalImages: note.relativeLocalImages),
              // 创建时间
              _buildCreateTime(note)
            ],
          ),
        ),
      ));
    }

    // 底部空白
    list.add(const ListTile());
    return list;
  }

  _buildNoteContent(EpisodeNote note) {
    if (note.noteContent.isEmpty) return Container();
    return ListTile(
      title: Text(
        note.noteContent,
        maxLines: 10,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(height: 1.5, fontSize: 16),
      ),
      style: ListTileStyle.drawer,
    );
  }

  _buildCreateTime(note) {
    String timeStr = TimeShowUtil.getShowDateTimeStr(note.createTime);
    if (timeStr.isEmpty) return Container();
    return ListTile(
      style: ListTileStyle.drawer,
      subtitle: Text("创建于 $timeStr"),
    );
  }
}
