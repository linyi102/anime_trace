import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/models/note_filter.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/components/note_img_view.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/pages/modules/note_edit.dart';
import 'package:flutter_test_future/pages/settings/image_path_setting.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';

class NoteListPage extends StatefulWidget {
  const NoteListPage({Key? key}) : super(key: key);

  @override
  _NoteListPageState createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  List<Note> episodeNotes = [];
  bool _loadOk = false;
  NoteFilter noteFilter = NoteFilter();

  final int _pageSize = 20;
  int _pageIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    //为了避免内存泄露，需要调用.dispose
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    _loadOk = false;
    _pageIndex = 1;

    Future(() {
      debugPrint("note_list_page: 开始加载数据");
      // return SqliteUtil.getAllNotesByTableHistory();
      return SqliteUtil.getAllNotesByTableNoteAndKeyword(
          0, _pageSize, noteFilter);
    }).then((value) {
      episodeNotes = value;
      _loadOk = true;
      debugPrint("note_list_page: 数据加载完成");
      debugPrint("笔记总数(不包括空笔记)：${episodeNotes.length}");
      setState(() {});
    });
  }

  void _loadMoreData(index) {
    if (index + 5 == _pageSize * (_pageIndex)) {
      _pageIndex++;
      debugPrint("再次请求$_pageSize个数据");
      Future(() {
        return SqliteUtil.getAllNotesByTableNoteAndKeyword(
            episodeNotes.length, _pageSize, noteFilter); // 偏移量为当前页面显示的数量
      }).then((value) {
        debugPrint("请求结束");
        episodeNotes.addAll(value);
        debugPrint("添加并更新状态，episodeNotes.length=${episodeNotes.length}");
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtil.getNoteListBackgroundColor(),
      appBar: AppBar(
        title: const Text(
          "笔记",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: _buildActions(),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: !_loadOk
              ? Container(
                  key: UniqueKey(),
                  // color: Colors.white,
                )
              : Scrollbar(controller: _scrollController, child: _buildNotes()),
        ),
      ),
    );
  }

  List<Widget> _buildActions() {
    var animeNameController = TextEditingController();
    var noteContentController = TextEditingController();
    return [
      IconButton(
          tooltip: "搜索",
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("搜索"),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: animeNameController
                            ..text = noteFilter.animeNameKeyword,
                          decoration: InputDecoration(
                              labelText: "动漫关键字",
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                  onPressed: () {
                                    animeNameController.text = "";
                                  },
                                  icon: const Icon(Icons.close),
                                  iconSize: 18)),
                        ),
                        TextField(
                          controller: noteContentController
                            ..text = noteFilter.noteContentKeyword,
                          decoration: InputDecoration(
                              labelText: "笔记关键字",
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                  onPressed: () {
                                    noteContentController.text = "";
                                  },
                                  icon: const Icon(Icons.close),
                                  iconSize: 18)),
                        )
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("取消")),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          noteFilter.animeNameKeyword =
                              animeNameController.text;
                          noteFilter.noteContentKeyword =
                              noteContentController.text;
                          _loadData();
                        },
                        child: const Text("搜索")),
                  ],
                );
              },
            );
          },
          icon: const Icon(Icons.search)),
      PopupMenuButton(
        icon: const Icon(Icons.more_vert),
        offset: const Offset(0, 50),
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem(
              padding: const EdgeInsets.all(0),
              child: ListTile(
                title: const Text("图片设置"),
                leading: const Icon(Icons.image_outlined),
                style: ListTileStyle.drawer,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, FadeRoute(
                    builder: (context) {
                      return const ImagePathSetting();
                    },
                  )).then((value) => _loadData());
                },
              ),
            ),
          ];
        },
      )
    ];
  }

  _buildNotes() {
    return episodeNotes.isEmpty
        ? emptyDataHint("暂无笔记", toastMsg: "点击已完成的集即可添加笔记")
        : ListView.builder(
            controller: _scrollController,
            itemCount: episodeNotes.length,
            itemBuilder: (BuildContext context, int index) {
              // debugPrint("index=$index");
              _loadMoreData(index);

              return Container(
                padding: const EdgeInsets.only(top: 5),
                child: Card(
                  elevation: 0,
                  child: MaterialButton(
                    elevation: 0,
                    padding: const EdgeInsets.all(0),
                    color: ThemeUtil.getNoteCardColor(),
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
                        _buildAnimeListTile(index),
                        // 笔记内容
                        _buildEpisodeNote(index),
                        // 笔记图片
                        NoteImgView(
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

  _enterAnimeDetail(int episodeNoteindex) {
    Navigator.of(context)
        .push(
      FadeRoute(
        transitionDuration: const Duration(milliseconds: 200),
        builder: (context) {
          return AnimeDetailPlus(episodeNotes[episodeNoteindex].anime.animeId);
        },
      ),
    )
        .then((value) {
      // _loadData(); // 会导致重新请求数据从而覆盖episodeNotes，而返回时应该要恢复到原来的位置
      Anime anime = value;
      // 如果animeId为0，说明进入动漫详细页后删除了动漫，需要从笔记列表中删除相关笔记
      if (!anime.isCollected()) {
        episodeNotes.removeWhere((element) =>
            element.anime.animeId ==
            episodeNotes[episodeNoteindex].anime.animeId);
      }
      setState(() {});
    });
  }

  _buildAnimeListTile(int index) {
    return ListTile(
      style: ListTileStyle.drawer,
      leading: GestureDetector(
        onTap: () {
          _enterAnimeDetail(index);
        },
        child: AnimeListCover(
          episodeNotes[index].anime,
          showReviewNumber: true,
          reviewNumber: episodeNotes[index].episode.reviewNumber,
        ),
      ),
      trailing: IconButton(
          onPressed: () {
            Navigator.of(context).push(
              FadeRoute(
                builder: (context) {
                  return NoteEdit(episodeNotes[index]);
                },
              ),
            ).then((value) {
              episodeNotes[index] = value; // 更新修改
              setState(() {});
            });
          },
          // icon: const Icon(Icons.more_vert_rounded)),
          icon:
              Icon(Icons.navigate_next, color: ThemeUtil.getIconButtonColor())),
      title: GestureDetector(
        onTap: () {
          _enterAnimeDetail(index);
        },
        child: Text(
          episodeNotes[index].anime.animeName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          // textAlign: TextAlign.right,
        ),
      ),
      subtitle: GestureDetector(
        onTap: () {
          _enterAnimeDetail(index);
        },
        child: Text(
          "第 ${episodeNotes[index].episode.number} 集 ${episodeNotes[index].episode.getDate()}",
          // textAlign: TextAlign.right,
        ),
      ),
    );
  }

  _buildEpisodeNote(int index) {
    if (episodeNotes[index].noteContent.isEmpty) return Container();
    return ListTile(
      title: Text(
        episodeNotes[index].noteContent,
        maxLines: 10,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(height: 1.5, fontSize: 16),
      ),
      style: ListTileStyle.drawer,
    );
  }
}
