import 'package:flutter/material.dart';

import 'package:flutter_test_future/components/fade_animated_switcher.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/dao/note_dao.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/models/note_filter.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../../../models/anime.dart';
import '../../../models/params/page_params.dart';
import '../../anime_detail/anime_detail.dart';
import '../../../components/note_card.dart';

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

  @override
  void dispose() {
    //为了避免内存泄露，需要调用.dispose
    _rateScrollController.dispose();
    super.dispose();
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

              Note note = rateNotes[index];

              return NoteCard(
                note,
                removeNote: () {
                  // 从notes中移除，并重绘整个页面
                  setState(() {
                    rateNotes.removeAt(index);
                  });
                },
                isRateNote: true,
                showAnimeTile: true,
                enterAnimeDetail: () => _enterAnimeDetail(note.anime),
              );
            },
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
            // 更新这个动漫(图片、评价、名字可能会发生变化)
            rateNotes[i].anime = anime;
          }
        }
        setState(() {});
      }
    });
  }
}
