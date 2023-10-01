import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/dao/episode_desc_dao.dart';
import 'package:flutter_test_future/dao/note_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/episode.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/pages/anime_collection/checklist_controller.dart';
import 'package:flutter_test_future/pages/anime_detail/controllers/anime_controller.dart';
import 'package:flutter_test_future/pages/anime_detail/widgets/note_image_list.dart';
import 'package:flutter_test_future/pages/modules/note_edit.dart';
import 'package:flutter_test_future/utils/common_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/widgets/common_divider.dart';

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
  bool _loadingNote = true;

  Episode get _episode => widget.episode;
  Anime get _anime => widget.animeController.anime;
  List<String> get tags => ChecklistController.to.tags;

  late Color checkedColor;

  @override
  void initState() {
    super.initState();

    // 不管有没有隐藏笔记，都去要查询，否则更多按钮中的状态不匹配(创建/编辑笔记等等)

    if (!_episode.noteLoaded) {
      // 如果没有查询过数据库中的笔记，则进行查询
      _loadNote();
    } else {
      // 已查询过数据库，直接去掉加载中状态
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
    checkedColor = Theme.of(context).unselectedWidgetColor;

    return Column(
      children: [
        _buildEpisodeTile(),
        if (!widget.hideNote &&
            !_loadingNote &&
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

    return Column(
      children: [
        InkWell(
          onTap: () {
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
                    style: AppTheme.noteStyle,
                  ),
                  style: ListTileStyle.drawer,
                ),

              // 没有图片时不显示，否则有固定高度
              if (note.relativeLocalImages.isNotEmpty)
                NoteImageHorizontalListView(note: note),
            ],
          ),
        ),
        const CommonDivider(),
      ],
    );
  }

  ListTile _buildEpisodeTile() {
    return ListTile(
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.25),
      selected:
          widget.animeController.mapSelected.containsKey(widget.episodeIndex),
      title: Text(
        // "第${_episode.number}集",
        _episode.caption,
        style: TextStyle(color: _episode.isChecked() ? checkedColor : null),
      ),
      // 没有完成时不显示subtitle
      subtitle: widget.episode.isChecked()
          ? Text(
              widget.episode.getDate(),
              style:
                  TextStyle(color: _episode.isChecked() ? checkedColor : null),
              // style: Theme.of(context).textTheme.bodySmall,
            )
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
      return IconButton(
        icon: const CircularProgressIndicator(strokeWidth: 2),
        onPressed: () {},
      );
    }

    return GestureDetector(
      // 避免长按穿透到ListTile导致多选
      onLongPress: () {},
      child: IconButton(
        splashRadius: 24,
        icon: const Icon(
          Icons.more_horiz,
          // size: 20,
        ),
        onPressed: () {
          showDialog(
              context: context,
              builder: (dialogContext) {
                return SimpleDialog(
                  children: [
                    ListTile(
                      title: const Text("选择时间"),
                      leading: const Icon(Icons.access_time),
                      onTap: () async {
                        // 退出对话框
                        Navigator.of(dialogContext).pop();

                        // 如果是多选状态则先退出
                        if (widget.animeController.multiSelected.value) {
                          widget.animeController.quitMultiSelectionMode();
                        }
                        // 添加到多选中，保证只有这一个
                        widget.animeController
                            .mapSelected[widget.episodeIndex] = true;
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
                        title: const Text("撤销时间"),
                        leading: const Icon(Icons.close),
                        onTap: () async {
                          // 退出对话框
                          Navigator.pop(dialogContext);

                          // 弹出确定对话框
                          _dialogRemoveDate();
                        },
                      ),
                    const CommonDivider(),
                    ListTile(
                      title: const Text("编辑标题"),
                      leading: const Icon(Icons.title),
                      onTap: () {
                        Navigator.pop(dialogContext);

                        _showDialogDescForm(dialogContext);
                      },
                    ),
                    const CommonDivider(),
                    ListTile(
                      title: Text("${_episode.note == null ? '创建' : '编辑'}笔记"),
                      leading: const Icon(Icons.edit),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _enterNoteEditPage(needCreate: true);
                      },
                    ),
                    if (_episode.note != null)
                      ListTile(
                        title: const Text("复制笔记"),
                        leading: const Icon(Icons.copy_rounded),
                        onTap: () {
                          CommonUtil.copyContent(_episode.note!.noteContent);
                          Navigator.pop(dialogContext);
                        },
                      ),
                    if (_episode.note != null)
                      ListTile(
                        title: const Text("删除笔记"),
                        leading: const Icon(Icons.delete_outline),
                        onTap: () {
                          _dialogDeleteConfirm();
                        },
                      )
                  ],
                );
              });
        },
      ),
    );
  }

  getPreviewCaption(int number, String title, bool hideDefault) {
    if (hideDefault) {
      return title;
    } else {
      return "第$number集 $title";
    }
  }

  _showDialogDescForm(
    BuildContext context,
  ) {
    bool hideDefault = _episode.desc?.hideDefault ?? false;
    TextEditingController textEditingController =
        TextEditingController(text: _episode.desc?.title);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("标题"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: textEditingController,
                  autofocus: true,
                  onChanged: (value) {
                    // 重绘预览文本
                    setState(() {});
                  },
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text("隐藏默认"),
                  subtitle: Text(
                      "预览：${getPreviewCaption(_episode.number, textEditingController.text, hideDefault)}"),
                  value: hideDefault,
                  onChanged: (value) {
                    // 重绘对话框
                    setState(() {
                      hideDefault = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("取消")),
            TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  var title = textEditingController.text;
                  if (_episode.desc == null) {
                    _episode.desc = EpisodeDesc(
                        id: 0,
                        animeId: _anime.animeId,
                        number: _episode.number,
                        title: title,
                        hideDefault: hideDefault);
                  } else {
                    _episode.desc!.title = title;
                    _episode.desc!.hideDefault = hideDefault;
                  }

                  if (_episode.desc!.notInsert) {
                    int newId = await EpisodeDescDao.insert(_episode.desc!);
                    _episode.desc!.id = newId;
                  } else {
                    await EpisodeDescDao.update(_episode.desc!);
                  }
                  // 重绘该集Widget
                  this.setState(() {});
                },
                child: const Text("确定")),
          ],
        ),
      ),
    );
  }

  _buildLeading() {
    return IconButton(
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
                AnimeDao.updateTagByAnimeId(_anime.animeId, _anime.tagName);
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
          color: _episode.isChecked() ? checkedColor : null,
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
                      AnimeDao.updateTagByAnimeId(
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
                    AnimeDao.updateTagByAnimeId(_anime.animeId, _anime.tagName);
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

      if (_episode.note == null && !_episode.isChecked()) {
        // 如果没有设置观看时间，且没有笔记，则提示创建
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("没有找到笔记"),
              content: const Text("需要立即创建吗？"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("取消")),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _enterNoteEditPage(needCreate: true);
                    },
                    child: const Text("创建")),
              ],
            );
          },
        );
      } else {
        // 如果已设置时间，那么自动创建笔记并进入编辑页
        _enterNoteEditPage();
      }
    }
  }

  /// 进入笔记编辑页
  void _enterNoteEditPage({bool needCreate = false}) async {
    // 四种情况：
    // 1.集完成后，单击可以进入笔记编辑页(如果没有笔记则会自动创建)
    // 2.集没有完成，但有笔记，那么可以直接进入
    // 3.即没有完成，更多按钮中点击创建笔记
    // 4.集没有完成，弹出了创建提示
    if (_episode.isChecked() || _episode.note != null || needCreate) {
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
        // 不能只重绘这一个
        // setState(() {});
        // 只要重回集页面
        widget.animeController.update([widget.animeController.episodeId]);
      }
    }
  }

  void _dialogRemoveDate() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('撤销'),
          content: const Text('确定撤销观看时间吗？'),
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
              child: const Text('确定'),
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
          content: const Text("确定删除笔记吗？"),
          actions: [
            TextButton(
              onPressed: () {
                // 关闭删除确定对话框和更多菜单对话框
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () async {
                // 关闭删除确定对话框和更多菜单对话框
                Navigator.of(context)
                  ..pop()
                  ..pop();

                if (_episode.note != null) {
                  if (await NoteDao.deleteNoteById(_episode.note!.id)) {
                    setState(() {
                      _episode.note = null;
                    });
                  } else {
                    ToastUtil.showText("删除失败！");
                  }
                }
              },
              child: Text("删除",
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            )
          ],
        );
      },
    );
  }
}
