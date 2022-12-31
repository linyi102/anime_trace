import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/components/fade_animated_switcher.dart';
import 'package:flutter_test_future/components/note_img_grid.dart';
import 'package:flutter_test_future/dao/note_dao.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/models/note_filter.dart';
import 'package:flutter_test_future/pages/modules/note_edit.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../../components/anime_list_cover.dart';
import '../../models/anime.dart';
import '../../models/params/page_params.dart';
import '../../utils/theme_util.dart';
import '../anime_detail/anime_detail.dart';

class EpisodeNoteListPage extends StatefulWidget {
  final NoteFilter noteFilter;
  const EpisodeNoteListPage({Key? key, required this.noteFilter})
      : super(key: key);

  @override
  State<EpisodeNoteListPage> createState() => _EpisodeNoteListPageState();
}

class _EpisodeNoteListPageState extends State<EpisodeNoteListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool loadEpisodeNoteOk = false;
  List<Note> episodeNotes = [];
  PageParams episodeNotePageParams = PageParams(pageSize: 20, pageIndex: 1);
  final ScrollController _noteScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadEpisodeNoteData();
  }

  void _loadEpisodeNoteData() async {
    loadEpisodeNoteOk = false;
    episodeNotePageParams.resetPageIndex();
    Future(() {
      debugPrint("note_list_page: 开始加载数据");
      // return SqliteUtil.getAllNotesByTableHistory();
      return NoteDao.getAllNotesByTableNoteAndKeyword(
          0, episodeNotePageParams.pageSize, widget.noteFilter);
    }).then((value) {
      episodeNotes = value;
      loadEpisodeNoteOk = true;
      debugPrint("note_list_page: 数据加载完成");
      debugPrint("当前笔记数量(不包括空笔记)：${episodeNotes.length}");
      setState(() {});
    });
  }

  void _loadMoreEpisodeNoteData(index) {
    if (index + 5 ==
        episodeNotePageParams.pageSize * episodeNotePageParams.pageIndex) {
      episodeNotePageParams.pageIndex++;
      debugPrint("再次请求${episodeNotePageParams.pageSize}个数据");
      Future(() {
        return NoteDao.getAllNotesByTableNoteAndKeyword(episodeNotes.length,
            episodeNotePageParams.pageSize, widget.noteFilter); // 偏移量为当前页面显示的数量
      }).then((value) {
        debugPrint("请求结束");
        episodeNotes.addAll(value);
        debugPrint("添加并更新状态，episodeNotes.length=${episodeNotes.length}");
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    //为了避免内存泄露，需要调用.dispose
    _noteScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EpisodeNoteListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint(widget.noteFilter.toString());
    _loadEpisodeNoteData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async {
        _loadEpisodeNoteData();
      },
      child: FadeAnimatedSwitcher(
          loadOk: loadEpisodeNoteOk, destWidget: _buildEpisodeNotes()),
    );
  }

  _buildEpisodeNotes() {
    return episodeNotes.isEmpty
        ? emptyDataHint("什么都没有", toastMsg: "点击已完成的集即可添加笔记")
        : Scrollbar(
            controller: _noteScrollController,
            child: ListView.builder(
              controller: _noteScrollController,
              itemCount: episodeNotes.length,
              itemBuilder: (BuildContext context, int index) {
                // debugPrint("$runtimeType: index=$index");
                _loadMoreEpisodeNoteData(index);

                return Container(
                  padding: const EdgeInsets.only(top: 5),
                  child: Card(
                    elevation: 0,
                    child: MaterialButton(
                      elevation: 0,
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                      onPressed: () {
                        Navigator.of(context).push(
                          // MaterialPageRoute(
                          //   builder: (context) => EpisodeNoteSF(episodeNotes[index]),
                          // ),
                          FadeRoute(
                            builder: (context) {
                              return NoteEdit(episodeNotes[index]);
                            },
                          ),
                        ).then((value) {
                          // 如果返回的笔记id为0，则说明已经从笔记列表页进入的动漫详细页删除了动漫，因此需要根据动漫id删除所有相关笔记
                          Note newEpisodeNote = value;
                          debugPrint(
                              "newEpisodeNote.anime.animeId=${newEpisodeNote.anime.animeId}");
                          if (newEpisodeNote.id == 0) {
                            episodeNotes.removeWhere((element) =>
                                element.anime.animeId ==
                                newEpisodeNote.anime.animeId);
                          } else {
                            episodeNotes[index] = newEpisodeNote; // 更新修改
                          }
                          setState(() {});
                        });
                      },
                      child: Flex(
                        direction: Axis.vertical,
                        children: [
                          // 动漫行
                          _buildAnimeListTile(
                              setState: setState,
                              context: context,
                              note: episodeNotes[index]),
                          // const Divider()
                          // 笔记内容
                          _buildNote(note: episodeNotes[index]),
                          // 笔记图片
                          NoteImgGrid(
                              relativeLocalImages:
                                  episodeNotes[index].relativeLocalImages),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
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

    // 单独给listtile的title添加GestureDetector点击事件时，因为title是一整行，所以点击文字后面的区域仍然会进入动漫详细页
    return ListTile(
      leading: GestureDetector(
        onTap: () => _enterAnimeDetail(context: context, anime: note.anime),
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
        ),
      ),
      subtitle: isRateNote
          ? null
          : GestureDetector(
              onTap: () =>
                  _enterAnimeDetail(context: context, anime: note.anime),
              child: Text(
                  "第${note.episode.number}集 ${note.episode.getDate()}",
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
        episodeNotes
            .removeWhere((element) => element.anime.animeId == anime.animeId);
        setState(() {});
      } else {
        // 否则重新获取该动漫的所有相关笔记的内容和图片，因为可能在详细页里进行了修改
        // 为什么不直接获取所有内容？因为note里有anime、episode还要获取，不用再次获取，因为这个肯定在详细页中不能改变
        for (int i = 0; i < episodeNotes.length; ++i) {
          // Note episodeNote = episodeNotes[i];
          // 必须都对episodeNotes[i]进行操作才能看到变化。for in也不行
          if (episodeNotes[i].anime.animeId == anime.animeId) {
            Note note = await NoteDao.getNoteContentAndImagesByNoteId(
                episodeNotes[i].id);
            episodeNotes[i].noteContent = note.noteContent;
            episodeNotes[i].relativeLocalImages = note.relativeLocalImages;
          }
        }
        setState(() {});
      }
    });
  }
}
