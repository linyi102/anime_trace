import 'dart:io';

import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_animated_switcher.dart';
import 'package:flutter_test_future/components/common_image.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/components/my_icon_button.dart';
import 'package:flutter_test_future/components/note_card.dart';
import 'package:flutter_test_future/components/rounded_sheet.dart';
import 'package:flutter_test_future/pages/anime_detail/controllers/anime_controller.dart';
import 'package:flutter_test_future/dao/note_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/episode.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/pages/anime_detail/widgets/episode_tile.dart';
import 'package:flutter_test_future/pages/modules/note_edit.dart';
import 'package:flutter_test_future/pages/modules/note_img_viewer.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:get/get.dart';
import 'package:sliver_tools/sliver_tools.dart';

class AnimeDetailEpisodeInfo extends StatefulWidget {
  const AnimeDetailEpisodeInfo({required this.animeController, super.key});
  final AnimeController animeController;

  @override
  State<AnimeDetailEpisodeInfo> createState() => _AnimeDetailEpisodeInfoState();
}

class _AnimeDetailEpisodeInfoState extends State<AnimeDetailEpisodeInfo> {
  Anime get _anime => widget.animeController.anime;
  List<Episode> get _episodes => widget.animeController.episodes;
  List<Note> get _notes => widget.animeController.notes;

  bool hideNoteInAnimeDetail =
      SPUtil.getBool("hideNoteInAnimeDetail", defaultValue: false);

  @override
  void initState() {
    super.initState();

    if (widget.animeController.isCollected) {
      widget.animeController.currentStartEpisodeNumber = SPUtil.getInt(
          "${_anime.animeId}-currentStartEpisodeNumber",
          defaultValue: 1);

      Future.delayed(const Duration(milliseconds: 200)).then((value) {
        // 200ms后再去请求数据，避免在页面过渡动画卡顿
        widget.animeController.loadEpisode();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);
    return _buildSliverListBody();
  }

  // 构建主体(集信息页)
  _buildSliverListBody() {
    // 不能使用MyAnimatedSwitcher，因为父级是slivers: []
    return SliverPadding(
      padding: const EdgeInsets.all(0),
      sliver: GetBuilder<AnimeController>(
        id: widget.animeController.episodeId,
        init: widget.animeController,
        initState: (_) {},
        builder: (_) {
          Log.info("build ${widget.animeController.episodeId}");

          // 如果没有收藏，则不展示集信息，注意需要放在GetBuilder里
          // 这样收藏后，其他地方执行animeController.loadEpisode()更新时就会看到变化
          if (!widget.animeController.isCollected) {
            return SliverToBoxAdapter(child: Container());
          }

          return SliverAnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: !widget.animeController.loadEpisodeOk
                ? _buildSliverLoadingWidget()
                : SliverList(
                    delegate:
                        SliverChildBuilderDelegate((context, episodeIndex) {
                      // Log.info(": episodeIndex=");

                      List<Widget> episodeInfo = [];
                      if (episodeIndex == 0) {
                        episodeInfo.add(_buildButtonsAboutEpisode());
                      }
                      episodeInfo.add(
                        _buildEpisodeTile(episodeIndex),
                      );

                      // 在每一集下面添加笔记
                      if (!hideNoteInAnimeDetail &&
                          _episodes[episodeIndex].isChecked()) {
                        episodeInfo.add(_buildNote(episodeIndex, context));
                      }

                      // 在最后一集下面添加空白
                      if (episodeIndex == _episodes.length - 1) {
                        episodeInfo.add(const ListTile());
                      }

                      return Column(
                        children: episodeInfo,
                      );
                    }, childCount: _episodes.length),
                  ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildSliverLoadingWidget() {
    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(top: 20),
          width: 20, // 可外套SizeBox指定大小，也可不指定
          height: 20,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  bool enableEpisodeRangeBottomSheetStyle = true;
  // 动漫信息下面的操作栏
  _buildButtonsAboutEpisode() {
    if (!_anime.isCollected()) return Container();
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              if (enableEpisodeRangeBottomSheetStyle) {
                showFlexibleBottomSheet(
                    context: context,
                    duration: const Duration(milliseconds: 200),
                    bottomSheetColor: Colors.transparent,
                    builder: (
                      BuildContext context,
                      ScrollController scrollController,
                      double bottomSheetOffset,
                    ) =>
                        RoundedSheet(
                          body: _buildEpisodeRangeGridView(),
                          title: const Text("选择区域"),
                          centerTitle: true,
                        ));
              } else {
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text("选择区域"),
                      content: SingleChildScrollView(
                        child: Wrap(
                          spacing: ThemeUtil.wrapSacing,
                          runSpacing: ThemeUtil.wrapRunSpacing,
                          children: _buildEpisodeRangeChips(dialogContext),
                        ),
                      ),
                    );
                  },
                );
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: EdgeInsets.fromLTRB(0, 3, 8, 3),
              child: Row(
                children: [
                  const Icon(Icons.arrow_right_rounded),
                  Text(_getEpisodeRangeStr(
                      widget.animeController.currentStartEpisodeNumber)),
                ],
              ),
            ),
          ),
          // _buildReviewNumberTextButton(),
          const SizedBox(width: 10),
          Expanded(child: Container()),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              MyIconButton(
                onPressed: _dialogSelectReviewNumber,
                // 使用自带图标
                // icon: _showReviewNumberIcon()
                // 绘制圆角方块，中间添加数字
                icon: Container(
                  width: 18,
                  height: 18,
                  child: Center(
                      child: Text("${_anime.reviewNumber}",
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w500))),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                          color: ThemeUtil
                                  .themeController.themeColor.value.isDarkMode
                              ? Colors.grey
                              : Colors.black,
                          width: 2)),
                ),
              ),
              MyIconButton(
                  onPressed: () {
                    if (hideNoteInAnimeDetail) {
                      // 原先隐藏，则设置为false，表示显示
                      SPUtil.setBool("hideNoteInAnimeDetail", false);
                      hideNoteInAnimeDetail = false;
                      // showToast("已展开笔记");
                    } else {
                      SPUtil.setBool("hideNoteInAnimeDetail", true);
                      hideNoteInAnimeDetail = true;
                      // showToast("已隐藏笔记");
                    }
                    setState(() {});
                  },
                  tooltip: hideNoteInAnimeDetail ? "显示笔记" : "隐藏笔记",
                  icon: hideNoteInAnimeDetail
                      ? const Icon(EvaIcons.expandOutline)
                      : const Icon(EvaIcons.collapseOutline)),
              // ? const Icon(Icons.unfold_more)
              // : const Icon(Icons.unfold_less)),
            ],
          ),
        ],
      ),
    );
  }

  _buildEpisodeRangeGridView() {
    return GridView(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          mainAxisExtent: 60, maxCrossAxisExtent: 120),
      padding: const EdgeInsets.all(8.0),
      children: () {
        List<Widget> items = [];
        for (var startEpisodeNumber = 1;
            startEpisodeNumber <= _anime.animeEpisodeCnt;
            startEpisodeNumber += widget.animeController.episodeRangeSize) {
          bool cur = widget.animeController.currentStartEpisodeNumber ==
              startEpisodeNumber;

          items.add(Card(
            elevation: 0,
            child: TextButton(
              // autofocus仅仅改变的是背景色
              // autofocus: cur ? true : false,
              onPressed: () {
                widget.animeController.currentStartEpisodeNumber =
                    startEpisodeNumber;
                SPUtil.setInt("${_anime.animeId}-currentStartEpisodeNumber",
                    widget.animeController.currentStartEpisodeNumber);
                Navigator.of(context).pop();
                // 获取集数据
                widget.animeController.loadEpisode();
              },
              child: Text(
                _getEpisodeRangeStr((startEpisodeNumber)),
                style: TextStyle(
                    color: cur
                        ? ThemeUtil.getPrimaryColor()
                        : ThemeUtil.getFontColor()),
              ),
            ),
          ));
        }
        return items;
      }(),
    );
  }

  _buildEpisodeTile(int episodeIndex) {
    return AnimeDetailEpisodeTile(
      episode: _episodes[episodeIndex],
      selected: widget.animeController.mapSelected.containsKey(episodeIndex),
      trailing: _buildEpisodeTileTrailing(episodeIndex),
      leading: _buildEpisodeTileLeading(episodeIndex),
      onTap: () {
        onpressEpisode(episodeIndex);
      },
      onLongPress: () async {
        onLongPressEpisode(episodeIndex);
      },
    );
  }

  _buildEpisodeTileLeading(int episodeIndex) {
    return MyIconButton(
      onPressed: () async {
        if (_episodes[episodeIndex].isChecked()) {
          _dialogRemoveDate(
            _episodes[episodeIndex].number,
            _episodes[episodeIndex].dateTime,
          ); // 这个函数执行完毕后，在执行下面的setState并不会更新页面，因此需要在该函数中使用setState
        } else {
          String date = DateTime.now().toString();
          SqliteUtil.insertHistoryItem(_anime.animeId,
              _episodes[episodeIndex].number, date, _anime.reviewNumber);
          _episodes[episodeIndex].dateTime = date;
          // 同时插入空笔记，记得获取最新插入的id，否则进入的是笔记0，会造成修改笔记无效
          Note episodeNote = Note(
              anime: _anime,
              episode: _episodes[episodeIndex],
              relativeLocalImages: [],
              imgUrls: []);

          // 一定要先添加笔记，否则episodeIndex会越界
          _notes.add(episodeNote);
          // 如果存在，恢复之前做的笔记。(完成该集并添加笔记后，又完成该集，需要恢复笔记)
          _notes[episodeIndex] = await NoteDao
              .getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(
                  episodeNote);
          // 不存在，则添加新笔记。因为获取笔记的函数中也实现了没有则添加新笔记，因此就不需要这个了
          // episodeNote.episodeNoteId =
          //     await SqliteUtil.insertEpisodeNote(episodeNote);
          // episodeNotes[i] = episodeNote; // 更新
          setState(() {});

          // 如果完成了最后一集(完结+当前集号为最大集号)，则提示是否要修改清单
          if (_episodes[episodeIndex].number == _anime.animeEpisodeCnt &&
              _anime.playStatus.contains("完结")) {
            // 之前点击了不再提示
            bool showModifyChecklistDialog =
                SPUtil.getBool("showModifyChecklistDialog", defaultValue: true);
            if (!showModifyChecklistDialog) return;

            // 获取之前选择的清单，如果是第一次则默认选中第一个清单，如果之前选的清单后来删除了，不在列表中，也要选中第一个清单
            String selectedFinishedTag =
                SPUtil.getString("selectedFinishedTag");
            bool existSelectedFinishedTag =
                tags.indexWhere((element) => selectedFinishedTag == element) !=
                    -1;
            if (!existSelectedFinishedTag) {
              selectedFinishedTag = tags[0];
            }

            // 之前点击了总是。那么就修改清单而不需要弹出对话框了
            if (existSelectedFinishedTag &&
                SPUtil.getBool("autoMoveToFinishedTag", defaultValue: false)) {
              _anime.tagName = selectedFinishedTag;
              SqliteUtil.updateTagByAnimeId(_anime.animeId, _anime.tagName);
              Log.info("修改清单为${_anime.tagName}");
              setState(() {});
              return;
            }

            // 弹出对话框
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
                                  selectedFinishedTag =
                                      value ?? selectedFinishedTag;
                                  dialogState(() {});
                                })
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () {
                              SPUtil.setBool(
                                  "showModifyChecklistDialog", false);
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
                              setState(() {});
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
                            setState(() {});
                            Navigator.pop(dialogContext);
                          },
                          child: const Text("仅本次"),
                        )
                      ],
                    );
                  });
                });
          }
        }
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _episodes[episodeIndex].isChecked()
            ? Icon(
                // Icons.check_box_outlined,
                // EvaIcons.checkmarkSquare2Outline,
                EvaIcons.checkmarkSquare,
                key: Key("$episodeIndex"), // 不能用unique，否则同状态的按钮都会有动画
                color: ThemeUtil.getEpisodeListTile(
                    _episodes[episodeIndex].isChecked()),
              )
            : Icon(
                // Icons.check_box_outline_blank,
                EvaIcons.square,
                color: ThemeUtil.getEpisodeListTile(
                    _episodes[episodeIndex].isChecked()),
              ),
      ),
    );
  }

  _buildEpisodeTileTrailing(int episodeIndex) {
    return MyIconButton(
      icon: const Icon(Icons.more_horiz),
      onPressed: () {
        showDialog(
            context: context,
            builder: (dialogContext) {
              return SimpleDialog(
                children: [
                  ListTile(
                    title: const Text("设置日期"),
                    leading: const Icon(Icons.edit_calendar_rounded),
                    style: ListTileStyle.drawer,
                    onTap: () async {
                      // 退出对话框
                      Navigator.of(dialogContext).pop();
                      // 先退出多选状态
                      widget.animeController.quitMultiSelectionMode();
                      // 添加到多选中，保证只有这一个
                      widget.animeController.mapSelected[episodeIndex] = true;
                      // 选择时间
                      await widget.animeController
                          .pickDateForEpisodes(context: context);
                      // 更新设置的时间
                      setState(() {});
                      // 清空多选
                      widget.animeController.mapSelected.clear();
                    },
                  )
                ],
              );
            });
      },
    );
  }

  void onpressEpisode(int episodeIndex) {
    // 多选
    if (widget.animeController.multiSelected.value) {
      if (widget.animeController.mapSelected.containsKey(episodeIndex)) {
        widget.animeController.mapSelected.remove(episodeIndex); // 选过，再选就会取消
        // 如果取消后一个都没选，就自动退出多选状态
        if (widget.animeController.mapSelected.isEmpty) {
          widget.animeController.multiSelected.value = false;
        }
      } else {
        widget.animeController.mapSelected[episodeIndex] = true;
        // 选择后，更新最后一次多选时选择的集下标(不管是选择还是又取消了，因为如果是取消，无法获取上一次短按的集下标)
        widget.animeController.lastMultiSelectedIndex = episodeIndex;
      }
      setState(() {});
    } else {
      if (_episodes[episodeIndex].isChecked()) {
        Navigator.of(context).push(
          // MaterialPageRoute(
          //     builder: (context) => EpisodeNoteSF(episodeNotes[i])),
          MaterialPageRoute(
            builder: (context) {
              return NoteEditPage(_notes[episodeIndex]);
            },
          ),
        ).then((value) {
          _notes[episodeIndex] = value; // 更新修改
          setState(() {});
        });
      }
    }
  }

  void onLongPressEpisode(int index) {
    final int lastMultiSelectedIndex =
        widget.animeController.lastMultiSelectedIndex;

    // 非多选状态下才需要进入多选状态
    if (widget.animeController.multiSelected.value == false) {
      widget.animeController.multiSelected.value = true;
      widget.animeController.mapSelected[index] = true;
      widget.animeController.lastMultiSelectedIndex =
          index; // 第一次也要设置最后一次多选的集下标
      setState(() {}); // 添加操作按钮
    } else {
      // 如果存在上一次多选集的下标，则将中间的所有集选择
      if (lastMultiSelectedIndex >= 0) {
        // 注意大小关系[lastMultiSelectedIndex, index]和[index, lastMultiSelectedIndex]
        int begin =
            lastMultiSelectedIndex < index ? lastMultiSelectedIndex : index;
        int end =
            lastMultiSelectedIndex > index ? lastMultiSelectedIndex : index;
        for (var i = begin; i <= end; i++) {
          widget.animeController.mapSelected[i] = true;
        }
        setState(() {});
      }
    }
  }

  _buildNote(int episodeIndex, BuildContext context) {
    // 由于排序后集列表排了序，但笔记列表没有排序，会造成笔记混乱，因此显示笔记时，根据该集的编号来找到笔记
    int noteIdx = _notes.indexWhere(
        (element) => element.episode.number == _episodes[episodeIndex].number);

    // return NoteCard(_notes[noteIdx]);
    return _buildNoteHorizontalCard(noteIdx);
  }

  _buildNoteHorizontalCard(int noteIdx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      child: _notes[noteIdx].relativeLocalImages.isEmpty &&
              _notes[noteIdx].noteContent.isEmpty
          ? Container()
          : Card(
              elevation: 0,
              color: ThemeUtil.getCardColor(),
              child: MaterialButton(
                padding: _notes[noteIdx].noteContent.isEmpty
                    ? const EdgeInsets.fromLTRB(0, 15, 0, 15)
                    : const EdgeInsets.fromLTRB(0, 5, 0, 15),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return NoteEditPage(_notes[noteIdx]);
                      },
                    ),
                  ).then((value) {
                    _notes[noteIdx] = value; // 更新修改
                    setState(() {});
                  });
                },
                child: Column(
                  children: [
                    // 笔记内容
                    _notes[noteIdx].noteContent.isEmpty
                        ? Container()
                        : ListTile(
                            title: Text(
                              _notes[noteIdx].noteContent,
                              maxLines: 10,
                              overflow: TextOverflow.ellipsis,
                              style: ThemeUtil.getNoteTextStyle(),
                            ),
                            style: ListTileStyle.drawer,
                          ),
                    // 没有图片时不显示，否则有固定高度
                    _notes[noteIdx].relativeLocalImages.isEmpty
                        ? Container()
                        :
                        // 图片横向排列
                        Container(
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                            height: 120, // 设置高度
                            // color: Colors.redAccent,
                            child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    _notes[noteIdx].relativeLocalImages.length,
                                itemBuilder: (context, imgIdx) {
                                  // Log.info("横向图片imgIdx=$imgIdx");
                                  return MaterialButton(
                                    padding: Platform.isAndroid
                                        ? const EdgeInsets.fromLTRB(5, 5, 5, 5)
                                        : const EdgeInsets.fromLTRB(
                                            15, 5, 15, 5),
                                    onPressed: () {
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (context) {
                                        // 点击图片进入图片浏览页面
                                        return ImageViewerPage(
                                          relativeLocalImages: _notes[noteIdx]
                                              .relativeLocalImages,
                                          initialIndex: imgIdx,
                                        );
                                      }));
                                    },
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: SizedBox(
                                          height: 100,
                                          width: 100,
                                          child: CommonImage(ImageUtil
                                              .getAbsoluteNoteImagePath(_notes[
                                                      noteIdx]
                                                  .relativeLocalImages[imgIdx]
                                                  .path)),
                                        )),
                                  );
                                }),
                          )
                    // ImageGridView(
                    //     relativeLocalImages:
                    //         _episodeNotes[episodeNoteIndex].relativeLocalImages)
                  ],
                ),
              ),
            ),
    );
  }

  void _dialogRemoveDate(int episodeNumber, String? date) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('是否撤销日期?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('否'),
            ),
            ElevatedButton(
              onPressed: () {
                SqliteUtil
                    .deleteHistoryItemByAnimeIdAndEpisodeNumberAndReviewNumber(
                        _anime.animeId, episodeNumber, _anime.reviewNumber);
                // 根据episodeNumber找到对应的下标
                int findIndex = _getEpisodeIndexByEpisodeNumber(episodeNumber);
                _episodes[findIndex].cancelDateTime();
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('是'),
            ),
          ],
        );
      },
    );
  }

  // 获取当前集范围的字符串形式
  String _getEpisodeRangeStr(int startEpisodeNumber) {
    if (_anime.animeEpisodeCnt == 0) {
      return "00-00";
    }
    int endEpisodeNumber =
        startEpisodeNumber + widget.animeController.episodeRangeSize - 1;
    if (endEpisodeNumber > _anime.animeEpisodeCnt) {
      endEpisodeNumber = _anime.animeEpisodeCnt;
    }

    return startEpisodeNumber.toString().padLeft(2, '0') +
        "-" +
        endEpisodeNumber.toString().padLeft(2, '0');
  }

  _buildEpisodeRangeChips(BuildContext dialogContext) {
    List<Widget> chips = [];
    for (var startEpisodeNumber = 1;
        startEpisodeNumber <= _anime.animeEpisodeCnt;
        startEpisodeNumber += widget.animeController.episodeRangeSize) {
      chips.add(GestureDetector(
        onTap: () {
          widget.animeController.currentStartEpisodeNumber = startEpisodeNumber;
          SPUtil.setInt("${_anime.animeId}-currentStartEpisodeNumber",
              widget.animeController.currentStartEpisodeNumber);
          Navigator.pop(dialogContext);
          // 获取集数据
          widget.animeController.loadEpisode();
        },
        child: Chip(
          label: Text(_getEpisodeRangeStr((startEpisodeNumber)),
              textScaleFactor: ThemeUtil.tinyScaleFactor),
          backgroundColor: widget.animeController.currentStartEpisodeNumber ==
                  startEpisodeNumber
              ? Colors.grey
              : null,
        ),
      ));
    }
    return chips;
  }

  // 如果设置了未完成的靠前，则完成某集后移到最后面
  // 如果取消了日期，还需要移到最前面。好麻烦...还得插入到合适的位置
  // 不改变位置的好处：误点击完成了，不用翻到最下面取消
  // void _moveToLastIfSet(int index) {
  //   // 先不用移到最后面吧
  //   // // 先移除，再添加
  //   // if (SPUtil.getBool("sortByUnCheckedFront")) {
  //   //   Episode episode = _episodes[index];
  //   //   _episodes.removeAt(index);
  //   //   _episodes.add(episode); // 不应该直接在后面添加，而是根据number插入到合适的位置。但还要注意越界什么的
  //   // }
  // }

  int _getEpisodeIndexByEpisodeNumber(int episodeNumber) {
    return _episodes.indexWhere((element) => element.number == episodeNumber);
  }

  void _dialogSelectReviewNumber() {
    dialogSelectUint(context, "选择第几次观看",
            initialValue: _anime.reviewNumber, minValue: 1, maxValue: 9)
        .then((value) {
      if (value != null) {
        if (_anime.reviewNumber != value) {
          _anime.reviewNumber = value;
          // SqliteUtil.updateAnimeReviewNumberByAnimeId(
          //     _anime.animeId, _anime.reviewNumber);
          SqliteUtil.updateAnime(_anime, _anime);
          // 不相等才设置并重新加载数据
          widget.animeController.loadEpisode();
        }
      }
    });
  }
}
