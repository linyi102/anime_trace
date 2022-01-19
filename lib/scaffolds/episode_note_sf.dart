import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/episode_note.dart';
import 'package:flutter_test_future/classes/relative_local_image.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/image_grid_item.dart';
import 'package:flutter_test_future/components/image_grid_view.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/note_setting.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:oktoast/oktoast.dart';

// ignore: must_be_immutable
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
                      style: ListTileStyle.drawer,
                      leading: AnimeListCover(widget.episodeNote.anime),
                      title: Text(
                        widget.episodeNote.anime.animeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                          "第 ${widget.episodeNote.episode.number} 集 ${widget.episodeNote.episode.getDate()}"),
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
      widget.episodeNote.relativeLocalImages.length + 1,
      (BuildContext context, int index) {
        if (index == widget.episodeNote.relativeLocalImages.length) {
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
                    if (!ImageUtil.hasImageRootDirPath()) {
                      showToast("请先设置图片根目录");
                      Navigator.of(context).push(
                        // MaterialPageRoute(
                        //   builder: (BuildContext context) =>
                        //       const NoteSetting(),
                        // ),
                        FadeRoute(
                          builder: (context) {
                            return const NoteSetting();
                          },
                        ),
                      );
                      return;
                    }
                    if (Platform.isWindows || Platform.isAndroid) {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['jpg', 'png', 'gif'],
                        allowMultiple: true,
                      );
                      if (result == null) return;
                      List<PlatformFile> platformFiles = result.files;
                      for (var platformFile in platformFiles) {
                        String absoluteImagePath = platformFile.path ?? "";
                        if (absoluteImagePath.isEmpty) continue;

                        String relativeImagePath =
                            ImageUtil.getRelativeImagePath(absoluteImagePath);
                        int imageId =
                            await SqliteUtil.insertNoteIdAndImageLocalPath(
                                widget.episodeNote.episodeNoteId,
                                relativeImagePath);
                        widget.episodeNote.relativeLocalImages.add(
                            RelativeLocalImage(imageId, relativeImagePath));
                      }
                    } else if (Platform.isAndroid) {
                      //
                    } else {
                      throw ("未适配平台：${Platform.operatingSystem}");
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
            ImageGridItem(
                relativeImagePath:
                    widget.episodeNote.relativeLocalImages[index].path),
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
                        RelativeLocalImage relativeLocalImage =
                            widget.episodeNote.relativeLocalImages[index];
                        // 删除数据库记录、删除该页中的图片
                        SqliteUtil.deleteLocalImageByImageId(
                            relativeLocalImage.imageId);
                        widget.episodeNote.relativeLocalImages.removeWhere(
                            (element) =>
                                element.imageId == relativeLocalImage.imageId);
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
