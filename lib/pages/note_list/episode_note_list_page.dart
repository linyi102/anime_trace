import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/components/fade_animated_switcher.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/components/note_img_grid.dart';
import 'package:flutter_test_future/dao/note_dao.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/models/note_filter.dart';
import 'package:flutter_test_future/pages/modules/note_edit.dart';

import '../../models/params/page_params.dart';
import 'note_common_build.dart';

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
      // child: loadEpisodeNoteOk
      //     ? Scrollbar(
      //         controller: _noteScrollController, child: _buildEpisodeNotes())
      //     : loadingWidget(context),
    );
  }

  _buildEpisodeNotes() {
    return episodeNotes.isEmpty
        ? emptyDataHint("什么都没有", toastMsg: "点击已完成的集即可添加笔记")
        : ListView.builder(
            controller: _noteScrollController,
            itemCount: episodeNotes.length,
            itemBuilder: (BuildContext context, int index) {
              _loadMoreEpisodeNoteData(index);

              return Container(
                padding: const EdgeInsets.only(top: 5),
                child: Card(
                  elevation: 0,
                  child: MaterialButton(
                    elevation: 0,
                    padding: const EdgeInsets.all(0),
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
                        if (newEpisodeNote.episodeNoteId == 0) {
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
                        NoteCommonBuild.buildAnimeListTile(
                            setState: setState,
                            context: context,
                            note: episodeNotes[index]),
                        // 笔记内容
                        NoteCommonBuild.buildNote(note: episodeNotes[index]),
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
          );
  }
}
