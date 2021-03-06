import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/episode_note.dart';
import 'package:flutter_test_future/classes/relative_local_image.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/image_grid_item.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/settings/note_setting.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:oktoast/oktoast.dart';

// ignore: must_be_immutable
class NoteEdit extends StatefulWidget {
  EpisodeNote episodeNote; // 可能会修改笔记内容，因此不能用final
  NoteEdit(this.episodeNote, {Key? key}) : super(key: key);

  @override
  State<NoteEdit> createState() => _NoteEditState();
}

class _NoteEditState extends State<NoteEdit> {
  bool _loadOk = false;
  bool _updateNoteContent = false; // 如果文本内容发生变化，返回时会更新数据库
  var noteContentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    noteContentController.text = widget.episodeNote.noteContent;
    debugPrint("进入笔记${widget.episodeNote.episodeNoteId}");
    _loadData();
  }

  _loadData() async {
    Future(() {
      return SqliteUtil.existNoteId(widget.episodeNote.episodeNoteId);
    }).then((existNoteId) {
      if (!existNoteId) {
        // 笔记id置0，从笔记编辑页返回到笔记列表页，接收到后根据动漫id删除所有相关笔记
        widget.episodeNote.episodeNoteId = 0;
        Navigator.of(context).pop(widget.episodeNote);
        showToast("未找到该笔记");
      }
      setState(() {
        _loadOk = true;
      });
    });
  }

  _onWillpop() {
    Navigator.pop(context, widget.episodeNote);
    if (_updateNoteContent) {
      SqliteUtil.updateEpisodeNoteContentByNoteId(
          widget.episodeNote.episodeNoteId, widget.episodeNote.noteContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 返回键
        _onWillpop();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              // 返回按钮
              onPressed: () {
                _onWillpop();
              },
              tooltip: "返回上一级",
              icon: const Icon(Icons.arrow_back_rounded)),
        ),
        body: _loadOk ? _buildBody() : Container(),
      ),
    );
  }

  _buildBody() {
    return Scrollbar(
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
          ),
          _showNoteContent(),
          _buildGridImages(),
        ],
      ),
    );
  }

  _showNoteContent() {
    return TextField(
      controller: noteContentController..text,
      decoration: const InputDecoration(
        hintText: "描述",
        border: InputBorder.none,
        contentPadding: EdgeInsets.fromLTRB(10, 15, 10, 15),
      ),
      maxLines: null,
      style: const TextStyle(height: 1.5, fontSize: 16),
      onChanged: (value) {
        _updateNoteContent = true;
        widget.episodeNote.noteContent = value;
      },
    );
  }

  _buildGridImages() {
    Color addColor = SPUtil.getBool("enableDark") ? Colors.grey : Colors.black;
    int itemCount =
        widget.episodeNote.relativeLocalImages.length + 1; // 加一是因为多了个添加图标

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 15, 10, 50),
      shrinkWrap: true, // ListView嵌套GridView
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Platform.isWindows ? 9 : 3, // 横轴数量
        crossAxisSpacing: 5, // 横轴距离
        mainAxisSpacing: 5, // 竖轴距离
        childAspectRatio: 1, // 网格比例。31/43为封面比例
      ),
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int imageIndex) {
        // 如果是最后一个下标，则设置添加图片图标
        if (imageIndex == widget.episodeNote.relativeLocalImages.length) {
          return Container(
            padding: const EdgeInsets.all(5.0),
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
                  child: Icon(Icons.add, color: addColor, size: 50)),
            ),
          );
        }

        // 否则显示图片
        return Stack(
          children: [
            ImageGridItem(
              relativeLocalImages: widget.episodeNote.relativeLocalImages,
              initialIndex: imageIndex,
            ),
            // 删除按钮
            Positioned(
              right: 0,
              top: 0,
              child: Transform.scale(
                alignment: Alignment.topRight,
                scale: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: const Color.fromRGBO(255, 255, 255, 0.1),
                  ),
                  child: IconButton(
                      onPressed: () {
                        _dialogRemoveImage(imageIndex);
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                      )),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  _dialogRemoveImage(int index) {
    return showDialog(
        context: context,
        builder: (context) {
          // 返回警告对话框
          return AlertDialog(
            title: const Text("提示"),
            content: const Text("确认移除该图片吗？"),
            // 动作集合
            actions: <Widget>[
              TextButton(
                child: const Text("取消"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: const Text("确认"),
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
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
}
