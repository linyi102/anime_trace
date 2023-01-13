import 'package:flutter/material.dart';

import 'package:flutter_test_future/models/episode.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/pages/modules/note_edit.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/time_show_util.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../../components/note_img_grid.dart';
import '../../dao/note_dao.dart';
import '../../models/anime.dart';
import '../../utils/theme_util.dart';

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

          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Card(
              elevation: 0,
              child: MaterialButton(
                elevation: 0,
                padding: const EdgeInsets.all(0),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return NoteEdit(note);
                      },
                    ),
                  ).then((value) {
                    // 重新获取列表
                    // _loadData();
                    // 不要重新获取，否则有时会直接跳到最上面，而不是上次浏览位置
                    // 也不需要重新获取，修改笔记返回后，笔记也会变化
                  });
                },
                child: Flex(
                  direction: Axis.vertical,
                  children: [
                    // 笔记内容
                    _buildNoteContent(note),
                    // 笔记图片
                    NoteImgGrid(relativeLocalImages: note.relativeLocalImages),
                    // 创建时间
                    _buildCreateTimeAndMoreAction(note)
                  ],
                ),
              ),
            ),
          );
        });
  }

  _buildNoteContent(Note note) {
    if (note.noteContent.isEmpty) return Container();
    return Container(
      alignment: Alignment.centerLeft,
      // 左填充15，这样就和图片对齐了
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: Text(
        note.noteContent,
        maxLines: 10,
        overflow: TextOverflow.ellipsis,
        style: ThemeUtil.getNoteTextStyle(),
      ),
    );
  }

  _buildCreateTimeAndMoreAction(Note note) {
    String timeStr = TimeShowUtil.getHumanReadableDateTimeStr(note.createTime);
    timeStr = timeStr.isEmpty ? "" : "创建于$timeStr";

    return ListTile(
        style: ListTileStyle.drawer,
        title: Text(
          timeStr,
          textScaleFactor: ThemeUtil.tinyScaleFactor,
          style: TextStyle(
              fontWeight: FontWeight.normal,
              color: ThemeUtil.getCommentColor()),
        ),
        trailing: IconButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text("删除笔记"),
                          style: ListTileStyle.drawer, // 变小
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  content: const Text("确定删除笔记吗？"),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        // 关闭删除确认对话框和更多菜单对话框
                                        Navigator.of(context)
                                          ..pop()
                                          ..pop();
                                      },
                                      child: const Text("取消"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        // 关闭删除确认对话框和更多菜单对话框
                                        Navigator.of(context)
                                          ..pop()
                                          ..pop();
                                        SqliteUtil.deleteNoteById(note.id)
                                            .then((val) {
                                          _loadData();
                                        });
                                      },
                                      child: const Text("确定"),
                                    )
                                  ],
                                );
                              },
                            );
                          },
                        )
                      ],
                    );
                  });
            },
            icon: const Icon(Icons.more_horiz)));
  }
}
