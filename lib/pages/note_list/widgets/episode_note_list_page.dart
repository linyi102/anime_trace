import 'package:flutter/material.dart';

import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/animation/fade_animated_switcher.dart';
import 'package:flutter_test_future/dao/episode_desc_dao.dart';
import 'package:flutter_test_future/dao/note_dao.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/models/note_filter.dart';
import 'package:flutter_test_future/components/note_card.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../../../models/anime.dart';
import '../../../models/params/page_params.dart';
import '../../anime_detail/anime_detail.dart';

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

  @override
  void dispose() {
    super.dispose();
    _noteScrollController.dispose();
  }

  void _loadEpisodeNoteData() async {
    loadEpisodeNoteOk = false;
    episodeNotePageParams.resetPageIndex();
    Log.info("note_list_page: 开始加载数据");
    // 获取集笔记
    episodeNotes = await NoteDao.getAllNotesByTableNoteAndKeyword(
        0, episodeNotePageParams.pageSize, widget.noteFilter);

    // 修正集编号
    for (var note in episodeNotes) {
      note.episode.desc =
          await EpisodeDescDao.query(note.anime.animeId, note.episode.number);
    }

    loadEpisodeNoteOk = true;
    Log.info("note_list_page: 数据加载完成");
    Log.info("当前笔记数量(不包括空笔记)：${episodeNotes.length}");
    if (mounted) setState(() {});
  }

  void _loadMoreEpisodeNoteData(index) {
    if (index + 5 ==
        episodeNotePageParams.pageSize * episodeNotePageParams.pageIndex) {
      episodeNotePageParams.pageIndex++;
      Log.info("再次请求${episodeNotePageParams.pageSize}个数据");
      Future(() {
        return NoteDao.getAllNotesByTableNoteAndKeyword(episodeNotes.length,
            episodeNotePageParams.pageSize, widget.noteFilter); // 偏移量为当前页面显示的数量
      }).then((value) {
        Log.info("请求结束");
        episodeNotes.addAll(value);
        Log.info("添加并更新状态，episodeNotes.length=${episodeNotes.length}");
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant EpisodeNoteListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    Log.info(widget.noteFilter.toString());
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
        ? emptyDataHint(msg: "没有笔记。")
        : Scrollbar(
            controller: _noteScrollController,
            child: ListView.builder(
              controller: _noteScrollController,
              itemCount: episodeNotes.length,
              itemBuilder: (BuildContext context, int index) {
                // Log.info("$runtimeType: index=$index");
                _loadMoreEpisodeNoteData(index);
                Note note = episodeNotes[index];

                return NoteCard(
                  note,
                  showAnimeTile: true,
                  enterAnimeDetail: () => _enterAnimeDetail(note.anime),
                  removeNote: () {
                    // 从notes中移除，并重绘整个页面
                    setState(() {
                      episodeNotes.removeAt(index);
                    });
                  },
                );
              },
            ),
          );
  }

  _enterAnimeDetail(Anime anime) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return AnimeDetailPage(anime);
        },
      ),
    ).then((value) async {
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
            // 更新这个动漫(图片、评价、名字可能会发生变化)
            episodeNotes[i].anime = anime;
          }
        }
        setState(() {});
      }
    });
  }
}
