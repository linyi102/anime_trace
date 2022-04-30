import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/episode_note.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/image_grid_view.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/scaffolds/episode_note_sf.dart';
import 'package:flutter_test_future/scaffolds/settings/note_setting.dart';
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
      appBar: AppBar(
        title: const Text(
          "笔记",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            offset: const Offset(0, 50),
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  // padding: const EdgeInsets.all(0),
                  child: ListTile(
                    title: hideAnimeListTile
                        ? const Text("显示动漫行")
                        : const Text("隐藏动漫行"),
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
          ),
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
              : Scrollbar(child: _showNotes()),
        ),
      ),
    );
  }

  _showNotes() {
    return ListView.builder(
      itemCount: episodeNotes.length,
      itemBuilder: (BuildContext context, int index) {
        // debugPrint("index=$index");
        _loadExtraData(index);

        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 5, 0, 15),
          child: Card(
            elevation: 1,
            child: MaterialButton(
              padding: const EdgeInsets.all(0),
              onPressed: () {
                Navigator.of(context).push(
                  // MaterialPageRoute(
                  //   builder: (context) => EpisodeNoteSF(episodeNotes[index]),
                  // ),
                  FadeRoute(
                    builder: (context) {
                      return EpisodeNoteSF(episodeNotes[index]);
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
                  // 显示笔记内容
                  episodeNotes[index].noteContent.isEmpty
                      ? Container()
                      : ListTile(
                          title: Text(
                            episodeNotes[index].noteContent,
                            maxLines: 10,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ListTileStyle.drawer,
                        ),
                  ImageGridView(
                      relativeLocalImages:
                          episodeNotes[index].relativeLocalImages), // 显示动漫行
                  hideAnimeListTile
                      ? Container()
                      : ListTile(
                          style: ListTileStyle.drawer,
                          leading: AnimeListCover(
                            episodeNotes[index].anime,
                            showReviewNumber: true,
                            reviewNumber:
                                episodeNotes[index].episode.reviewNumber,
                          ),
                          trailing: IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  FadeRoute(
                                    builder: (context) {
                                      return EpisodeNoteSF(episodeNotes[index]);
                                    },
                                  ),
                                ).then((value) {
                                  episodeNotes[index] = value; // 更新修改
                                  setState(() {});
                                });
                              },
                              icon: const Icon(Icons.edit)),
                          title: Text(
                            episodeNotes[index].anime.animeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            // textAlign: TextAlign.right,
                          ),
                          subtitle: Text(
                            "第 ${episodeNotes[index].episode.number} 集 ${episodeNotes[index].episode.getDate()}",
                            // textAlign: TextAlign.right,
                          ),
                          onTap: () {
                            Navigator.of(context)
                                .push(
                              // MaterialPageRoute(
                              //   builder: (context) => AnimeDetailPlus(
                              //       episodeNotes[index].anime.animeId),
                              // ),
                              FadeRoute(
                                transitionDuration:
                                    const Duration(milliseconds: 0),
                                builder: (context) {
                                  return AnimeDetailPlus(
                                      episodeNotes[index].anime.animeId);
                                },
                              ),
                            )
                                .then((value) {
                              // _loadData(); // 会导致重新请求数据从而覆盖episodeNotes，而返回时应该要恢复到原来的位置
                            });
                          },
                        ),
                ],
              ),
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
}
