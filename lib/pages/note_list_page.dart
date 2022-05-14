import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/episode_note.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/image_grid_view.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/scaffolds/note_edit.dart';
import 'package:flutter_test_future/scaffolds/settings/note_setting.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';

class NoteListPage extends StatefulWidget {
  const NoteListPage({Key? key}) : super(key: key);

  @override
  _NoteListPageState createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  List<EpisodeNote> episodeNotes = [];
  bool _loadOk = false;
  bool hideAnimeListTile = SPUtil.getBool("hideAnimeListTile");

  final int _pageSize = 20;
  int _pageIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _loadOk = false;
    _pageIndex = 1;

    Future(() {
      debugPrint("note_list_page: 开始加载数据");
      // return SqliteUtil.getAllNotesByTableHistory();
      return SqliteUtil.getAllNotesByTableNote(0, _pageSize);
    }).then((value) {
      episodeNotes = value;
      _loadOk = true;
      debugPrint("note_list_page: 数据加载完成");
      debugPrint("笔记总数(不包括空笔记)：${episodeNotes.length}");
      setState(() {});
    });
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
        actions: [
          _buildActions(),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: RefreshIndicator(
          onRefresh: () async {
            _loadData();
          },
          child: !_loadOk
              ? Container(
                  key: UniqueKey(),
                  // color: Colors.white,
                )
              : Scrollbar(child: _buildNotes()),
        ),
      ),
    );
  }

  PopupMenuButton<dynamic> _buildActions() {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert),
      offset: const Offset(0, 50),
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            // padding: const EdgeInsets.all(0),
            child: ListTile(
              title:
                  hideAnimeListTile ? const Text("显示动漫行") : const Text("隐藏动漫行"),
              style: ListTileStyle.drawer,
              // trailing: Icon(Icons.remove_red_eye),
              onTap: () {
                if (hideAnimeListTile) {
                  SPUtil.setBool("hideAnimeListTile", false);
                } else {
                  SPUtil.setBool("hideAnimeListTile", true);
                }
                setState(() {
                  hideAnimeListTile = SPUtil.getBool("hideAnimeListTile");
                });
                Navigator.pop(context);
              },
            ),
          ),
          PopupMenuItem(
            // padding: const EdgeInsets.all(0),
            child: ListTile(
              title: const Text("更多设置"),
              style: ListTileStyle.drawer,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, FadeRoute(
                  builder: (context) {
                    return const NoteSetting();
                  },
                )).then((value) => _loadData());
              },
            ),
          ),
        ];
      },
    );
  }

  _buildNotes() {
    return episodeNotes.isEmpty
        ? const Center(
            child: Text("暂无笔记，完成某集后点击即可添加笔记"),
          )
        : ListView.builder(
            itemCount: episodeNotes.length,
            itemBuilder: (BuildContext context, int index) {
              // debugPrint("index=$index");
              _loadExtraData(index);

              return Container(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
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
                      episodeNotes[index] = value; // 更新修改
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
                      ImageGridView(
                          relativeLocalImages:
                              episodeNotes[index].relativeLocalImages),
                    ],
                  ),
                ),
              );
            },
          );
  }

  void _loadExtraData(index) {
    if (index + 5 == _pageSize * (_pageIndex)) {
      _pageIndex++;
      debugPrint("再次请求$_pageSize个数据");
      Future(() {
        return SqliteUtil.getAllNotesByTableNote(
            episodeNotes.length, _pageSize); // 偏移量为当前页面显示的数量
      }).then((value) {
        debugPrint("请求结束");
        episodeNotes.addAll(value);
        debugPrint("添加并更新状态，episodeNotes.length=${episodeNotes.length}");
        setState(() {});
      });
    }
  }

  _enterAnimeDetail(int episodeNoteindex) {
    Navigator.of(context)
        .push(
      // MaterialPageRoute(
      //   builder: (context) => AnimeDetailPlus(
      //       episodeNotes[index].anime.animeId),
      // ),
      FadeRoute(
        transitionDuration: const Duration(milliseconds: 0),
        builder: (context) {
          return AnimeDetailPlus(episodeNotes[episodeNoteindex].anime.animeId);
        },
      ),
    )
        .then((value) {
      // _loadData(); // 会导致重新请求数据从而覆盖episodeNotes，而返回时应该要恢复到原来的位置
    });
  }

  _buildAnimeListTile(int index) {
    if (hideAnimeListTile) return Container();
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
          icon: const Icon(
            Icons.edit,
            color: Colors.grey,
          )),
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
