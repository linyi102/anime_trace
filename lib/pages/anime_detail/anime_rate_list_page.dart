import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
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
import '../modules/anime_rating_bar.dart';

// 动漫详细页的评价列表tab
class AnimeRateListPage extends StatefulWidget {
  final Anime anime;

  const AnimeRateListPage(this.anime, {Key? key}) : super(key: key);

  @override
  State<AnimeRateListPage> createState() => _AnimeRateListPageState();
}

class _AnimeRateListPageState extends State<AnimeRateListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late Anime anime;
  List<Note> notes = [];
  bool noteOk = false;

  @override
  void initState() {
    super.initState();
    anime = widget.anime;
    _loadData();
  }

  _loadData() {
    noteOk = false;
    NoteDao.getRateNotesByAnimeId(anime.animeId).then((value) {
      notes = value;
      // 把所有笔记都指定anime
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
    super.build(context);

    return Scaffold(
      appBar: AppBar(
          title: const Text("动漫评价",
              style: TextStyle(fontWeight: FontWeight.w600))),
      body: Padding(
        padding: const EdgeInsetsDirectional.all(5),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Padding(
              //   padding: const EdgeInsets.only(top: 10),
              //   child: _buildRatingStars(),
              // ),
              _buildRateCard(),
              noteOk
                  ? notes.isNotEmpty
                      ? Column(children: _buildRateNoteList())
                      : Container()
                  : Container()
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createRateNote(context),
        backgroundColor: ThemeUtil.getPrimaryIconColor(),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  _buildRateCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("评分：${anime.rate}/5"),
          _buildRatingStars(),
          const SizedBox(height: 30),
          Text("${notes.length}条评价")
        ],
      ),
    );
    return Container(
      height: 80,
      width: 210,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: ThemeUtil.getCardColor()),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Text("评分：${anime.rate}/5"),
            ),
            Align(
                alignment: AlignmentDirectional.center,
                child: _buildRatingStars()),
            Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: Text(
                "${notes.length}条评价",
                textScaleFactor: 0.8,
              ),
            )
          ],
        ),
      ),
    );
  }

  _buildRatingStars() {
    return AnimeRatingBar(
        rate: anime.rate,
        onRatingUpdate: (v) {
          Log.info("评价分数：$v");
          setState(() {
            anime.rate = v.toInt();
          });
          SqliteUtil.updateAnimeRate(anime.animeId, anime.rate);
        });
  }

  void _createRateNote(BuildContext context) {
    Log.info("添加评价");
    Note episodeNote = Note(anime: anime, episode: Episode(0, 1), // 第0集作为评价
        relativeLocalImages: [], imgUrls: []);
    NoteDao.insertEpisodeNote(episodeNote).then((value) {
      // 获取到刚插入的笔记id，然后再进入笔记
      episodeNote.id = value;
      Navigator.push(
              context, FadeRoute(builder: (context) => NoteEdit(episodeNote)))
          .then((value) {
        // 重新获取列表
        _loadData();
      });
    });
  }

  _buildRateNoteList() {
    List<Widget> list = [];
    Log.info("渲染1次评价笔记列表"); // TODO：多次渲染

    for (Note note in notes) {
      list.add(ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Card(
          elevation: 0,
          child: MaterialButton(
            elevation: 0,
            padding: const EdgeInsets.all(0),
            onPressed: () {
              Navigator.of(context).push(
                FadeRoute(
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
      ));
    }

    // 底部空白
    list.add(const ListTile());
    return list;
  }

  _buildNoteContent(Note note) {
    if (note.noteContent.isEmpty) return Container();
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Text(
        note.noteContent,
        maxLines: 10,
        overflow: TextOverflow.ellipsis,
        style: ThemeUtil.getNoteTextStyle(),
      ),
    );
    // return ListTile(
    //   title: Text(
    //     note.noteContent,
    //     maxLines: 10,
    //     overflow: TextOverflow.ellipsis,
    //     style: const TextStyle(height: 1.5, fontSize: 16),
    //   ),
    //   style: ListTileStyle.drawer,
    // );
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
