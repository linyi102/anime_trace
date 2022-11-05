import 'package:flutter/material.dart';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/models/episode.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/pages/modules/note_edit.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/time_show_util.dart';
import 'package:fluttericon/typicons_icons.dart';

import '../../components/note_img_grid.dart';
import '../../dao/note_dao.dart';
import '../../models/anime.dart';
import '../../utils/theme_util.dart';

class RateListPage extends StatefulWidget {
  final Anime anime;

  const RateListPage(this.anime, {Key? key}) : super(key: key);

  @override
  State<RateListPage> createState() => _RateListPageState();
}

class _RateListPageState extends State<RateListPage> {
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
      setState(() {
        noteOk = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _buildRatingStars(),
            IconButton(
                tooltip: "评价",
                onPressed: () => _createRateNote(context),
                icon: Icon(Icons.edit_note,
                    color: ThemeUtil.getCommonIconColor()))
          ]),
        ),
        noteOk
            ? notes.isNotEmpty
                ? Column(children: _buildRateNoteList())
                : Container()
            : Container()
      ],
    );
  }

  RatingStars _buildRatingStars() {
    return RatingStars(
        value: anime.rate.toDouble(),
        onValueChanged: (v) {
          setState(() {
            anime.rate = v.toInt();
          });
          SqliteUtil.updateAnimeRate(anime.animeId, anime.rate);
        },
        starBuilder: (index, color) => Icon(Typicons.star_filled, color: color),
        starCount: 5,
        starSize: 40,
        valueLabelColor: const Color(0xff9b9b9b),
        valueLabelTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
          // fontSize: 12.0
        ),
        valueLabelRadius: 10,
        maxValue: 5,
        starSpacing: 2,
        maxValueVisibility: false,
        valueLabelVisibility: false,
        animationDuration: const Duration(milliseconds: 0),
        valueLabelPadding:
            const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
        valueLabelMargin: const EdgeInsets.only(right: 8),
        starOffColor: const Color.fromRGBO(206, 214, 224, 1),
        starColor: const Color.fromRGBO(255, 167, 2, 1));
  }

  void _createRateNote(BuildContext context) {
    debugPrint("添加评价");
    Note episodeNote = Note(anime: anime, episode: Episode(0, 1), // 第0集作为评价
        relativeLocalImages: [], imgUrls: []);
    NoteDao.insertEpisodeNote(episodeNote).then((value) {
      // 获取到刚插入的笔记id，然后再进入笔记
      episodeNote.episodeNoteId = value;
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
    debugPrint("渲染1次笔记列表"); // TODO：多次渲染

    for (Note note in notes) {
      list.add(Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: ClipRRect(
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
    timeStr = timeStr.isEmpty ? "" : "创建于 $timeStr";

    return ListTile(
        style: ListTileStyle.drawer,
        title: Text(
          timeStr,
          textScaleFactor: ThemeUtil.tinyScaleFactor,
          style: TextStyle(
              fontWeight: FontWeight.normal,
              color: ThemeUtil.getCommentColor()),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_horiz),
          offset: const Offset(0, 50),
          itemBuilder: (BuildContext popUpMenuContext) {
            return [
              PopupMenuItem(
                padding: const EdgeInsets.all(0), // 变小
                child: ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text("删除笔记"),
                  style: ListTileStyle.drawer, // 变小
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text("确定删除笔记吗？"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                Navigator.pop(popUpMenuContext);
                              },
                              child: const Text("取消"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // 关闭对话框
                                Navigator.pop(dialogContext);
                                SqliteUtil.deleteNoteById(note.episodeNoteId)
                                    .then((val) {
                                  // 关闭下拉菜单，并重新获取评价列表
                                  Navigator.pop(popUpMenuContext);
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
                ),
              ),
            ];
          },
        ));
  }
}
