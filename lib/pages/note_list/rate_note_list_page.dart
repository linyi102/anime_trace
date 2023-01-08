import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/components/fade_animated_switcher.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/components/note_img_grid.dart';
import 'package:flutter_test_future/dao/note_dao.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/models/note_filter.dart';
import 'package:flutter_test_future/pages/modules/note_edit.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../../components/anime_list_cover.dart';
import '../../models/anime.dart';
import '../../models/params/page_params.dart';
import '../../utils/sqlite_util.dart';
import '../../utils/time_show_util.dart';
import '../anime_detail/anime_detail.dart';

class RateNoteListPage extends StatefulWidget {
  final NoteFilter noteFilter;

  const RateNoteListPage({Key? key, required this.noteFilter})
      : super(key: key);

  @override
  State<RateNoteListPage> createState() => _RateNoteListPageState();
}

class _RateNoteListPageState extends State<RateNoteListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // 评价
  bool loadRateNodeOk = false;
  List<Note> rateNotes = [];
  PageParams rateNotePageParams = PageParams(pageSize: 20, pageIndex: 1);
  final ScrollController _rateScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadRateNoteData();
  }

  void _loadRateNoteData() {
    loadRateNodeOk = false;
    rateNotePageParams.resetPageIndex();

    NoteDao.getRateNotes(
            pageParams: rateNotePageParams, noteFilter: widget.noteFilter)
        .then((value) {
      rateNotes = value;
      loadRateNodeOk = true;
      setState(() {});
      Log.info("共找到${rateNotes.length}条评价笔记");
    });
  }

  void _loadMoreRateNoteData(index) {
    if (index + 5 ==
        rateNotePageParams.pageSize * rateNotePageParams.pageIndex) {
      rateNotePageParams.pageIndex++;
      Log.info("再次请求${rateNotePageParams.pageSize}个数据");
      Future(() {
        return NoteDao.getRateNotes(
            pageParams: rateNotePageParams, noteFilter: widget.noteFilter);
      }).then((value) {
        Log.info("请求结束");
        rateNotes.addAll(value);
        Log.info("rateNotes.length=${rateNotes.length}");
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    //为了避免内存泄露，需要调用.dispose
    _rateScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RateNoteListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadRateNoteData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      child: FadeAnimatedSwitcher(
          loadOk: loadRateNodeOk,
          destWidget: Scrollbar(
            controller: _rateScrollController,
            child: _buildRateNotes(),
          )),
      onRefresh: () async {
        _loadRateNoteData();
      },
    );
  }

  _buildRateNotes() {
    return rateNotes.isEmpty
        ? emptyDataHint("什么都没有")
        : ListView.builder(
            controller: _rateScrollController,
            itemCount: rateNotes.length,
            itemBuilder: (BuildContext context, int index) {
              // Log.info("$runtimeType: index=$index");
              _loadMoreRateNoteData(index);

              return Container(
                padding: const EdgeInsets.only(top: 5),
                child: Card(
                  elevation: 0,
                  child: MaterialButton(
                    elevation: 0,
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      Navigator.of(context).push(
                        FadeRoute(
                          builder: (context) {
                            return NoteEdit(rateNotes[index]);
                          },
                        ),
                      ).then((value) {
                        // 更新笔记
                        rateNotes[index] = value;
                        setState(() {});
                      });
                    },
                    child: Flex(
                      direction: Axis.vertical,
                      children: [
                        // 因为listtile缺少subtitle，所以会靠近卡片顶部，因此添加一个sizedbox
                        const SizedBox(height: 10),
                        // 动漫行
                        _buildAnimeListTile(
                            setState: setState,
                            context: context,
                            note: rateNotes[index]),
                        // 笔记内容
                        _buildNote(note: rateNotes[index]),
                        // 笔记图片
                        NoteImgGrid(
                            relativeLocalImages:
                                rateNotes[index].relativeLocalImages),
                        // 显示日期和操作
                        _buildCreateTimeAndMoreAction(rateNotes[index])
                      ],
                    ),
                  ),
                ),
              );
            },
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
        trailing: _buildMoreButton(note));
  }

  PopupMenuButton<dynamic> _buildMoreButton(Note note) {
    return PopupMenuButton(
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
                            SqliteUtil.deleteNoteById(note.id).then((val) {
                              // 关闭下拉菜单，并重新获取评价列表
                              Navigator.pop(popUpMenuContext);
                              // 将笔记从中移除
                              rateNotes.removeWhere(
                                  (element) => element.id == note.id);
                              setState(() {});
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
    );
  }

  _buildNote({required Note note}) {
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

  _buildAnimeListTile(
      {required setState, required BuildContext context, required Note note}) {
    bool isRateNote = note.episode.number == 0;

    return ListTile(
      leading: AnimeListCover(
        note.anime,
        showReviewNumber: true,
        reviewNumber: note.episode.reviewNumber,
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

  _enterAnimeDetail({required BuildContext context, required Anime anime}) {
    Navigator.of(context)
        .push(
      FadeRoute(
        transitionDuration: const Duration(milliseconds: 200),
        builder: (context) {
          return AnimeDetailPlus(anime);
        },
      ),
    )
        .then((value) async {
      // // _loadData(); // 会导致重新请求数据从而覆盖episodeNotes，而返回时应该要恢复到原来的位置
      Anime anime = value;
      // 如果animeId为0，说明进入动漫详细页后删除了动漫，需要从笔记列表中删除相关笔记
      if (!anime.isCollected()) {
        rateNotes
            .removeWhere((element) => element.anime.animeId == anime.animeId);
        setState(() {});
      } else {
        // 否则重新获取该动漫的所有相关笔记的内容和图片，因为可能在详细页里进行了修改
        // 为什么不直接获取所有内容？因为note里有anime、episode还要获取，不用再次获取，因为这个肯定在详细页中不能改变
        for (int i = 0; i < rateNotes.length; ++i) {
          // Note episodeNote = episodeNotes[i];
          // 必须都对episodeNotes[i]进行操作才能看到变化。for in也不行
          if (rateNotes[i].anime.animeId == anime.animeId) {
            Note note =
                await NoteDao.getNoteContentAndImagesByNoteId(rateNotes[i].id);
            rateNotes[i].noteContent = note.noteContent;
            rateNotes[i].relativeLocalImages = note.relativeLocalImages;
          }
        }
        setState(() {});
      }
    });
  }
}
