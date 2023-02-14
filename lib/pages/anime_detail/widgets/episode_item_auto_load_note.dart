import 'dart:io';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_image.dart';
import 'package:flutter_test_future/components/my_icon_button.dart';
import 'package:flutter_test_future/dao/note_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/episode.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/pages/anime_detail/controllers/anime_controller.dart';
import 'package:flutter_test_future/pages/modules/note_edit.dart';
import 'package:flutter_test_future/pages/modules/note_img_viewer.dart';
import 'package:flutter_test_future/utils/common_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:oktoast/oktoast.dart';

/// 集+自动获取笔记

class EpisodeItemAutoLoadNote extends StatefulWidget {
  const EpisodeItemAutoLoadNote(
      {required this.animeController,
      required this.episode,
      required this.episodeIndex,
      this.trailing,
      required this.hideNote,
      super.key});
  final AnimeController animeController;
  final Episode episode;
  final int episodeIndex;
  final Widget? trailing;
  final bool hideNote;

  @override
  State<EpisodeItemAutoLoadNote> createState() =>
      _EpisodeItemAutoLoadNoteState();
}

class _EpisodeItemAutoLoadNoteState extends State<EpisodeItemAutoLoadNote> {
  final Color _multiSelectedColor =
      ThemeUtil.getPrimaryColor().withOpacity(0.25);

  bool _loadingNote = true;

  Episode get _episode => widget.episode;
  Anime get _anime => widget.animeController.anime;

  @override
  void initState() {
    super.initState();

    if (!_episode.noteLoaded) {
      _loadNote();
    } else {
      // 已查询过数据库
      if (mounted) {
        setState(() {
          _loadingNote = false;
        });
      }
    }
  }

  _loadNote() async {
    // await Future.delayed(const Duration(seconds: 2));

    // if (_episode.isChecked())
    // 不管有没有完成都去尝试获取
    _episode.note =
        await NoteDao.getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(
            _anime, _episode);
    // 不管有没有笔记，都记录为加载结束
    _episode.noteLoaded = true;
    // 重绘
    if (mounted) {
      setState(() {
        _loadingNote = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildEpisodeTile(),
        if (!_loadingNote &&
            _episode.note != null &&
            (_episode.note!.noteContent.isNotEmpty ||
                _episode.note!.relativeLocalImages.isNotEmpty))
          _buildNoteCard(),
      ],
    );
  }

  _buildNoteCard() {
    Note note = _episode.note!;
    // return NoteCard(note);

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      child: Card(
        elevation: 0,
        color: ThemeUtil.getCardColor(),
        child: MaterialButton(
          padding: note.noteContent.isEmpty
              ? const EdgeInsets.fromLTRB(0, 15, 0, 15)
              : const EdgeInsets.fromLTRB(0, 5, 0, 15),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return NoteEditPage(note);
                },
              ),
            ).then((value) {
              setState(() {
                note = value; // 更新修改
              });
            });
          },
          child: Column(
            children: [
              // 笔记内容
              if (note.noteContent.isNotEmpty)
                ListTile(
                  title: Text(
                    note.noteContent,
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                    style: ThemeUtil.getNoteTextStyle(),
                  ),
                  style: ListTileStyle.drawer,
                ),

              // 没有图片时不显示，否则有固定高度
              if (note.relativeLocalImages.isNotEmpty)
                // 图片横向排列
                Container(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                  height: 120, // 设置高度
                  // color: Colors.redAccent,
                  child: _buildHorizontalImages(note),
                )
            ],
          ),
        ),
      ),
    );
  }

  ListView _buildHorizontalImages(Note note) {
    return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: note.relativeLocalImages.length,
        itemBuilder: (context, imgIdx) {
          // Log.info("横向图片imgIdx=$imgIdx");
          return MaterialButton(
            padding: Platform.isAndroid
                ? const EdgeInsets.fromLTRB(5, 5, 5, 5)
                : const EdgeInsets.fromLTRB(15, 5, 15, 5),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                // 点击图片进入图片浏览页面
                return ImageViewerPage(
                  relativeLocalImages: note.relativeLocalImages,
                  initialIndex: imgIdx,
                );
              }));
            },
            child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: CommonImage(ImageUtil.getAbsoluteNoteImagePath(
                      note.relativeLocalImages[imgIdx].path)),
                )),
          );
        });
  }

  ListTile _buildEpisodeTile() {
    return ListTile(
      selectedTileColor: _multiSelectedColor,
      selected:
          widget.animeController.mapSelected.containsKey(widget.episodeIndex),
      title: Text("第${_episode.number}集",
          style: TextStyle(
              color: ThemeUtil.getEpisodeListTile(_episode.isChecked()))),
      // 没有完成时不显示subtitle
      subtitle: widget.episode.isChecked()
          ? Text(widget.episode.getDate(),
              style: TextStyle(
                  color: ThemeUtil.getEpisodeListTile(_episode.isChecked())),
              textScaleFactor: ThemeUtil.smallScaleFactor)
          : null,
      onTap: () => onpressEpisode(),
      onLongPress: () => onLongPressEpisode(),
      leading: _buildLeading(),
      trailing: _buildEpisodeTileTrailing(),
    );
  }

  _buildEpisodeTileTrailing() {
    // 如果还在加载笔记，则不显示更多按钮，避免打开后创建笔记
    if (_loadingNote) {
      return const MyIconButton(
        icon: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return MyIconButton(
      icon: const Icon(Icons.more_horiz),
      onPressed: () {
        showDialog(
            context: context,
            builder: (dialogContext) {
              return SimpleDialog(
                children: [
                  ListTile(
                    title: const Text("设置观看时间"),
                    leading: const Icon(EvaIcons.clockOutline),
                    onTap: () async {
                      // 退出对话框
                      Navigator.of(dialogContext).pop();

                      // 如果是多选状态则先退出
                      if (widget.animeController.multiSelected.value) {
                        widget.animeController.quitMultiSelectionMode();
                      }
                      // 添加到多选中，保证只有这一个
                      widget.animeController.mapSelected[widget.episodeIndex] =
                          true;
                      // 选择时间
                      await widget.animeController
                          .pickDateForEpisodes(context: context);
                      // 清空多选
                      widget.animeController.mapSelected.clear();
                      // 更新设置的时间
                      setState(() {});
                    },
                  ),
                  if (_episode.isChecked())
                    ListTile(
                      title: const Text("撤销观看时间"),
                      leading: const Icon(EvaIcons.undo),
                      onTap: () async {
                        // 退出对话框
                        Navigator.pop(dialogContext);

                        // 弹出确认对话框
                        _dialogRemoveDate();
                      },
                    ),
                  const Divider(),
                  ListTile(
                    title: Text("${_episode.note == null ? '创建' : '编辑'}笔记"),
                    leading: const Icon(EvaIcons.edit2Outline),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      _enterNoteEditPage(needCreate: true);
                    },
                  ),
                  if (_episode.note != null)
                    ListTile(
                      title: const Text("复制笔记内容"),
                      leading: const Icon(EvaIcons.copyOutline),
                      onTap: () {
                        CommonUtil.copyContent(_episode.note!.noteContent);
                        Navigator.pop(dialogContext);
                      },
                    ),
                  if (_episode.note != null)
                    ListTile(
                      title: const Text("删除笔记"),
                      leading: const Icon(EvaIcons.trash2Outline),
                      onTap: () {
                        _dialogDeleteConfirm();
                      },
                    )
                ],
              );
            });
      },
    );
  }

  _buildLeading() {
    return MyIconButton(
        onPressed: () async {
          if (_episode.isChecked()) {
            _dialogRemoveDate(); // 这个函数执行完毕后，在执行下面的setState并不会更新页面，因此需要在该函数中使用setState
          } else {
            String date = DateTime.now().toString();
            SqliteUtil.insertHistoryItem(
                _anime.animeId, _episode.number, date, _anime.reviewNumber);
            _episode.dateTime = date;
            setState(() {});

            // 如果完成了最后一集(完结+当前集号为最大集号)，则提示是否要修改清单
            if (_episode.number == _anime.animeEpisodeCnt &&
                _anime.playStatus.contains("完结")) {
              // 之前点击了不再提示
              bool showModifyChecklistDialog = SPUtil.getBool(
                  "showModifyChecklistDialog",
                  defaultValue: true);
              if (!showModifyChecklistDialog) return;

              // 获取之前选择的清单，如果是第一次则默认选中第一个清单，如果之前选的清单后来删除了，不在列表中，也要选中第一个清单
              String selectedFinishedTag =
                  SPUtil.getString("selectedFinishedTag");
              bool existSelectedFinishedTag = tags.indexWhere(
                      (element) => selectedFinishedTag == element) !=
                  -1;
              if (!existSelectedFinishedTag) {
                selectedFinishedTag = tags[0];
              }

              // 之前点击了总是。那么就修改清单而不需要弹出对话框了
              if (existSelectedFinishedTag &&
                  SPUtil.getBool("autoMoveToFinishedTag",
                      defaultValue: false)) {
                _anime.tagName = selectedFinishedTag;
                SqliteUtil.updateTagByAnimeId(_anime.animeId, _anime.tagName);
                Log.info("修改清单为${_anime.tagName}");
                setState(() {});
                return;
              }

              // 弹出对话框
              _showDialogAutoMoveChecklist(selectedFinishedTag);
            }
          }
        },
        icon: Icon(
          _episode.isChecked() ? EvaIcons.checkmarkSquare : EvaIcons.square,
          color: ThemeUtil.getEpisodeListTile(_episode.isChecked()),
        ));
  }

  _showDialogAutoMoveChecklist(String selectedFinishedTag) {
    showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (context, dialogState) {
            return AlertDialog(
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("已看完最后一集，\n是否需要移动清单？"),
                    DropdownButton<String>(
                        dropdownColor: ThemeUtil.getCardColor(),
                        value: selectedFinishedTag,
                        items: tags
                            .map((e) => DropdownMenuItem(
                                  child: Text(e),
                                  value: e,
                                ))
                            .toList(),
                        onChanged: (value) {
                          selectedFinishedTag = value ?? selectedFinishedTag;
                          dialogState(() {});
                        })
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      SPUtil.setBool("showModifyChecklistDialog", false);
                      Navigator.pop(dialogContext);
                    },
                    child: const Text("不再提醒")),
                TextButton(
                    onPressed: () {
                      SPUtil.setBool("autoMoveToFinishedTag", true);

                      _anime.tagName = selectedFinishedTag;
                      SPUtil.setString(
                          "selectedFinishedTag", selectedFinishedTag);
                      SqliteUtil.updateTagByAnimeId(
                          _anime.animeId, _anime.tagName);
                      Log.info("修改清单为${_anime.tagName}");
                      // 更新info
                      widget.animeController
                          .update([widget.animeController.infoId]);

                      Navigator.pop(dialogContext);
                    },
                    child: const Text("总是")),
                TextButton(
                  onPressed: () {
                    _anime.tagName = selectedFinishedTag;
                    SPUtil.setString(
                        "selectedFinishedTag", selectedFinishedTag);
                    SqliteUtil.updateTagByAnimeId(
                        _anime.animeId, _anime.tagName);
                    Log.info("修改清单为${_anime.tagName}");
                    // 更新info
                    widget.animeController
                        .update([widget.animeController.infoId]);

                    Navigator.pop(dialogContext);
                  },
                  child: const Text("仅本次"),
                )
              ],
            );
          });
        });
  }

  /// 单击某集
  void onpressEpisode() async {
    if (widget.animeController.multiSelected.value) {
      // 多选状态下
      if (widget.animeController.mapSelected.containsKey(widget.episodeIndex)) {
        widget.animeController.mapSelected
            .remove(widget.episodeIndex); // 选过，再选就会取消
        // 如果取消后一个都没选，就自动退出多选状态
        if (widget.animeController.mapSelected.isEmpty) {
          widget.animeController.multiSelected.value = false;
        }
      } else {
        widget.animeController.mapSelected[widget.episodeIndex] = true;
        // 选择后，更新最后一次多选时选择的集下标(不管是选择还是又取消了，因为如果是取消，无法获取上一次短按的集下标)
        widget.animeController.lastMultiSelectedIndex = widget.episodeIndex;
      }
      setState(() {});
    } else {
      // 没有多选时，进入笔记编辑页
      _enterNoteEditPage();
    }
  }

  /// 进入笔记编辑页
  void _enterNoteEditPage({bool needCreate = false}) async {
    if (_episode.isChecked() || needCreate) {
      // 如果没有笔记(为null)，那么先插入到数据库中
      if (_episode.note == null) {
        _episode.note = Note.createEpisodeNote(_anime, _episode);
        _episode.note!.id = await NoteDao.insertEpisodeNote(_episode.note!);
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return NoteEditPage(_episode.note!);
          },
        ),
      ).then((value) {
        _episode.note = value;
        setState(() {});
      });
    }
  }

  void onLongPressEpisode() {
    final int lastMultiSelectedIndex =
        widget.animeController.lastMultiSelectedIndex;

    // 非多选状态下才需要进入多选状态
    if (widget.animeController.multiSelected.value == false) {
      widget.animeController.multiSelected.value = true;
      widget.animeController.mapSelected[widget.episodeIndex] = true;
      widget.animeController.lastMultiSelectedIndex =
          widget.episodeIndex; // 第一次也要设置最后一次多选的集下标
      setState(() {}); // 添加操作按钮
    } else {
      // 如果存在上一次多选集的下标，则将中间的所有集选择
      if (lastMultiSelectedIndex >= 0) {
        // 注意大小关系[lastMultiSelectedIndex, index]和[index, lastMultiSelectedIndex]
        int begin = lastMultiSelectedIndex < widget.episodeIndex
            ? lastMultiSelectedIndex
            : widget.episodeIndex;
        int end = lastMultiSelectedIndex > widget.episodeIndex
            ? lastMultiSelectedIndex
            : widget.episodeIndex;
        for (var i = begin; i <= end; i++) {
          widget.animeController.mapSelected[i] = true;
        }
        setState(() {});
      }
    }
  }

  void _dialogRemoveDate() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认撤销观看时间吗？'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                SqliteUtil
                    .deleteHistoryItemByAnimeIdAndEpisodeNumberAndReviewNumber(
                        _anime.animeId, _episode.number, _anime.reviewNumber);
                setState(() {
                  _episode.cancelDateTime();
                });
                Navigator.pop(context);
              },
              child: const Text('撤销', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  _dialogDeleteConfirm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text("确认删除笔记吗？"),
          actions: [
            TextButton(
              onPressed: () {
                // 关闭删除确认对话框和更多菜单对话框
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () async {
                // 关闭删除确认对话框和更多菜单对话框
                Navigator.of(context)
                  ..pop()
                  ..pop();

                if (_episode.note != null) {
                  if (await NoteDao.deleteNoteById(_episode.note!.id)) {
                    setState(() {
                      _episode.note = null;
                    });
                  } else {
                    showToast("删除失败！");
                  }
                }
              },
              child: const Text("删除", style: TextStyle(color: Colors.red)),
            )
          ],
        );
      },
    );
  }
}
