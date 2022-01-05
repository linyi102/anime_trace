import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/episode_note.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/image_grid_item.dart';
import 'package:flutter_test_future/components/image_grid_view.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/utils/file_picker_util.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:path/path.dart';

class EpisodeNoteSF extends StatefulWidget {
  EpisodeNote episodeNote;
  EpisodeNoteSF(this.episodeNote, {Key? key}) : super(key: key);

  @override
  State<EpisodeNoteSF> createState() => _EpisodeNoteSFState();
}

class _EpisodeNoteSFState extends State<EpisodeNoteSF> {
  bool _loadOk = false;
  var noteContentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint("进入笔记${widget.episodeNote.episodeNoteId}");
    _loadData();
  }

  _loadData() async {
    Future(() {}).then((value) {
      // 增加添加图片的格子
      setState(() {
        _loadOk = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        debugPrint("按返回键，返回episodeNote");
        Navigator.pop(context, widget.episodeNote);
        SqliteUtil.updateEpisodeNoteContentByNoteId(
            widget.episodeNote.episodeNoteId, widget.episodeNote.noteContent);
        debugPrint("返回true");
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                debugPrint("按返回按钮，返回episodeNote");
                Navigator.pop(context, widget.episodeNote);
                SqliteUtil.updateEpisodeNoteContentByNoteId(
                    widget.episodeNote.episodeNoteId,
                    widget.episodeNote.noteContent);
              },
              tooltip: "返回上一级",
              icon: const Icon(Icons.arrow_back_rounded)),
          foregroundColor: Colors.black,
          // title: Text(
          //     "${widget.episodeNote.anime.animeName}>第 ${widget.episodeNote.episode.number} 集"),
        ),
        body: _loadOk
            ? Scrollbar(
                child: ListView(
                  children: [
                    ListTile(
                      // style: ListTileStyle.drawer,
                      leading: AnimeListCover(widget.episodeNote.anime),
                      title: Text(
                        "${widget.episodeNote.anime.animeName} ${widget.episodeNote.episode.number}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(widget.episodeNote.episode.getDate()),
                      // onTap: () {
                      //   Navigator.of(context).push(MaterialPageRoute(
                      //       builder: (context) => AnimeDetailPlus(
                      //           widget.episodeNote.anime.animeId)));
                      // },
                    ),
                    _showNoteContent(),
                    _showImages(),
                  ],
                ),
              )
            : Container(),
      ),
    );
  }

  _showNoteContent() {
    return TextField(
      controller: noteContentController..text = widget.episodeNote.noteContent,
      decoration: const InputDecoration(
        hintText: "描述",
        border: InputBorder.none,
        contentPadding: EdgeInsets.fromLTRB(15, 15, 15, 0),
      ),
      maxLines: null,
      style: const TextStyle(height: 1.5, fontSize: 16),
      onChanged: (value) {
        widget.episodeNote.noteContent = value;
      },
    );
  }

  _showImages() {
    Color addColor = Colors.black;
    return showImageGridView(
      widget.episodeNote.imgLocalPaths.length + 1,
      (BuildContext context, int index) {
        if (index == widget.episodeNote.imgLocalPaths.length) {
          return Container(
            decoration: BoxDecoration(
              // color: Colors.white,
              border: Border.all(
                width: 2,
                style: BorderStyle.solid,
                color: addColor,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: MaterialButton(
                  onPressed: () async {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles(
                            // allowedExtensions: ['jpg', 'png', 'gif'],
                            allowMultiple: true);
                    if (result == null) return;
                    List<PlatformFile> platformFiles = result.files;
                    String newDirPath =
                        "${ImageUtil.rootImageDirPath}/${widget.episodeNote.anime.animeId}/${widget.episodeNote.episode.number}";
                    // String newDirPath = join(
                    //     ImageUtil.rootImageDirPath,
                    //     widget.episodeNote.anime.animeId.toString(),
                    //     widget.episodeNote.episode.number.toString());

                    await Directory(newDirPath).create(recursive: true); // 创建目录
                    for (var platformFile in platformFiles) {
                      String newImagePath = "$newDirPath/${platformFile.name}";
                      File file = File(platformFile.path as String);
                      // File(newImagePath).create(); // 对于windows，需要先创建文件，然后才能拷贝
                      await file
                          .copy(newImagePath); // 必须拷贝完后才重新加载页面，否则有时会显示找不到文件
                      widget.episodeNote.imgLocalPaths.add(newImagePath);
                      // debugPrint("拷贝的图片路径：$newImagePath");
                      SqliteUtil.insertNoteIdAndImageLocalPath(
                          widget.episodeNote.episodeNoteId, newImagePath);
                    }
                    setState(() {});
                  },
                  child: Icon(
                    Icons.add,
                    color: addColor,
                  )),
            ),
          );
        }
        return Stack(
          children: [
            ImageGridItem(widget.episodeNote.imgLocalPaths[index]),
            Positioned(
              right: 0,
              top: 0,
              child: Transform.scale(
                alignment: Alignment.topRight,
                scale: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: const Color.fromRGBO(255, 255, 255, 0.1),
                  ),
                  child: IconButton(
                      onPressed: () {
                        String imgLocalPath =
                            widget.episodeNote.imgLocalPaths[index];
                        // 删除数据库记录、删除本地图片、删除该页中的图片
                        SqliteUtil.deleteLocalImageByImageLocalPath(
                            imgLocalPath);
                        widget.episodeNote.imgLocalPaths
                            .removeWhere((element) => element == imgLocalPath);
                        File(imgLocalPath).delete();
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.black,
                      )),
                ),
              ),
            )
          ],
        );
      },
    );
  }
}
