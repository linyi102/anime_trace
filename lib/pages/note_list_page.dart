import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/episode_note.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/image_grid_item.dart';
import 'package:flutter_test_future/components/image_grid_view.dart';
import 'package:flutter_test_future/scaffolds/episode_note_sf.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';

class NoteListPage extends StatefulWidget {
  const NoteListPage({Key? key}) : super(key: key);

  @override
  _NoteListPageState createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  List<EpisodeNote> episodeNotes = [];
  bool _loadOk = false;

  @override
  void initState() {
    super.initState();
    Future(() {
      debugPrint("note_list_page: 开始加载数据");
      return SqliteUtil.getAllNotes();
    }).then((value) {
      episodeNotes = value;
      _loadOk = true;
      debugPrint("note_list_page: 数据加载完成");
      debugPrint(episodeNotes.length.toString());
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      child: !_loadOk
          ? Container(
              key: UniqueKey(),
              // color: Colors.white,
            )
          : Scrollbar(child: _showNotes()),
    );
  }

  _showNotes() {
    return ListView.builder(
      itemCount: episodeNotes.length,
      itemBuilder: (BuildContext context, int index) {
        if (episodeNotes[index].noteContent.isEmpty &&
            episodeNotes[index].imgLocalPaths.isEmpty) return Container();
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
            child: Card(
              // color: Colors.red,
              elevation: 0,
              child: MaterialButton(
                padding: const EdgeInsets.all(0),
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (context) =>
                              EpisodeNoteSF(episodeNotes[index])))
                      .then((value) {
                    episodeNotes[index] = value; // 更新修改
                    setState(() {});
                  });
                },
                child: Column(
                  children: [
                    ListTile(
                      // style: ListTileStyle.drawer,
                      leading: AnimeListCover(episodeNotes[index].anime),
                      title: Text(
                        "${episodeNotes[index].anime.animeName} ${episodeNotes[index].episode.number}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(episodeNotes[index].episode.getDate()),
                    ),
                    episodeNotes[index].noteContent.isEmpty &&
                            episodeNotes[index].imgLocalPaths.isEmpty
                        ? Container()
                        : const Divider(),
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
                    episodeNotes[index].imgLocalPaths.length == 1
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(5), // 圆角
                            child: Image.file(
                              File(episodeNotes[index].imgLocalPaths[0]),
                              fit: BoxFit.fitHeight,
                            ),
                          )
                        : showImageGridView(
                            episodeNotes[index].imgLocalPaths.length,
                            (BuildContext context, int index1) {
                            return ImageGridItem(
                                episodeNotes[index].imgLocalPaths[index1]);
                          }),
                    // episodeNotes[index].noteContent.isEmpty &&
                    //         episodeNotes[index].imgLocalPaths.isEmpty
                    //     ? Container()
                    //     : const Divider(),
                    // ListTile(
                    //   trailing: AnimeListCover(episodeNotes[index].anime),
                    //   title: Text(
                    //     "${episodeNotes[index].anime.animeName} ${episodeNotes[index].episode.number}",
                    //     maxLines: 1,
                    //     overflow: TextOverflow.ellipsis,
                    //     textAlign: TextAlign.right,
                    //   ),
                    //   subtitle: Text(
                    //     episodeNotes[index].episode.getDate(),
                    //     textAlign: TextAlign.right,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }
}
