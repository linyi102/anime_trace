import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/episode_note.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/image_grid_item.dart';
import 'package:flutter_test_future/components/image_grid_view.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/scaffolds/episode_note_sf.dart';
import 'package:flutter_test_future/utils/image_util.dart';
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
    Future(() {
      debugPrint("note_list_page: 开始加载数据");
      // return SqliteUtil.getAllNotesByTableHistory();
      return SqliteUtil.getAllNotesByTableNote(0, _pageSize);
    }).then((value) {
      episodeNotes = value;
      _loadOk = true;
      debugPrint("note_list_page: 数据加载完成");
      debugPrint("笔记总数(包括空笔记)：${episodeNotes.length}");
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
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
          IconButton(
              onPressed: () {
                if (hideAnimeListTile) {
                  SPUtil.setBool("hideAnimeListTile", false);
                } else {
                  SPUtil.setBool("hideAnimeListTile", true);
                }
                setState(() {
                  hideAnimeListTile = SPUtil.getBool("hideAnimeListTile");
                });
              },
              icon: hideAnimeListTile
                  ? const Icon(Icons.unfold_more)
                  : const Icon(Icons.unfold_less)),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: !_loadOk
            ? Container(
                key: UniqueKey(),
                // color: Colors.white,
              )
            : Scrollbar(child: _showNotes()),
      ),
    );
  }

  _showNotes() {
    return ListView.builder(
      itemCount: episodeNotes.length,
      itemBuilder: (BuildContext context, int index) {
        // debugPrint("index=$index");
        _loadExtraData(index);
        // 跳过空笔记
        if (episodeNotes[index].noteContent.isEmpty &&
            episodeNotes[index].relativeLocalImages.isEmpty) {
          return Container();
        }
        // 会导致windows出错
        // MultiImageProvider multiImageProvider = MultiImageProvider(
        //   episodeNotes[index]
        //       .imgLocalPaths
        //       .map((imgLocalPath) => Image.file(File(imgLocalPath)).image)
        //       .toList(),
        // );
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
          child: Card(
            elevation: 0,
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
                  episodeNotes[index].relativeLocalImages.length == 1
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(15, 30, 15, 30),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5), // 圆角
                            child: Image.file(
                              File(ImageUtil.getAbsoluteImagePath(
                                  episodeNotes[index]
                                      .relativeLocalImages[0]
                                      .path)),
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                        )
                      : showImageGridView(
                          episodeNotes[index].relativeLocalImages.length,
                          (BuildContext context, int indexImage) {
                          return ImageGridItem(
                            // multiImageProvider: multiImageProvider,
                            relativeImagePath: episodeNotes[index]
                                .relativeLocalImages[indexImage]
                                .path,
                            initialIndex: 0, // 并没有发挥作用
                          );
                        }),
                  // episodeNotes[index].noteContent.isEmpty &&
                  //         episodeNotes[index].relativeLocalImages.isEmpty
                  //     ? Container() // 内容和图片都为空，则不显示
                  //     : hideAnimeListTile
                  //         ? Container() // 如果隐藏了AnimeListTile，则不显示分割线
                  //         : const Divider(),
                  hideAnimeListTile
                      ? Container()
                      : ListTile(
                          style: ListTileStyle.drawer,
                          trailing: AnimeListCover(episodeNotes[index].anime),
                          title: Text(
                            episodeNotes[index].anime.animeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                          subtitle: Text(
                            "第 ${episodeNotes[index].episode.number} 集 ${episodeNotes[index].episode.getDate()}",
                            textAlign: TextAlign.right,
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

                  // Padding(
                  //   padding: const EdgeInsets.all(8.0),
                  //   child: Row(
                  //     children: [
                  //       Expanded(
                  //         child: Text(
                  //           "完成于${episodeNotes[index].episode.getDate()}",
                  //           textAlign: TextAlign.left,
                  //         ),
                  //       ),
                  //       Expanded(
                  //         child: Text(
                  //           "${episodeNotes[index].anime.animeName} ${episodeNotes[index].episode.number}",
                  //           textAlign: TextAlign.right,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
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
