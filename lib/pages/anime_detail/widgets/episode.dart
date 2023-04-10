import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/components/my_icon_button.dart';
import 'package:flutter_test_future/pages/anime_detail/controllers/anime_controller.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/episode.dart';
import 'package:flutter_test_future/pages/anime_detail/widgets/episode_item_auto_load_note.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
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

  bool hideNoteInAnimeDetail =
      SPUtil.getBool("hideNoteInAnimeDetail", defaultValue: false);

  @override
  void initState() {
    super.initState();

    if (widget.animeController.isCollected) {
      widget.animeController.currentStartEpisodeNumber = SPUtil.getInt(
          "${_anime.animeId}-currentStartEpisodeNumber",
          defaultValue: 1);

      widget.animeController.loadEpisode();
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
                      var episode = _episodes[episodeIndex];
                      Log.info(
                          "episodeIndex=$episodeIndex, episode.noteLoaded=${episode.noteLoaded}");

                      List<Widget> episodeInfo = [];
                      if (episodeIndex == 0) {
                        episodeInfo.add(_buildButtonsAboutEpisode());
                      }
                      episodeInfo.add(
                        _buildEpisodeTile(episodeIndex),
                      );

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
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: const Text("选择区域"),
                      automaticallyImplyLeading: false,
                    ),
                    body: _buildEpisodeRangeGridView(),
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text("选择区域"),
                      content: SingleChildScrollView(
                        child: Wrap(
                          spacing: AppTheme.wrapSacing,
                          runSpacing: AppTheme.wrapRunSpacing,
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
              padding: const EdgeInsets.fromLTRB(0, 3, 8, 3),
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
                  width: 24,
                  height: 24,
                  child: Center(
                      child: Text("${_anime.reviewNumber}",
                          style: Theme.of(context).textTheme.labelLarge)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color:
                            Theme.of(context).iconTheme.color ?? Colors.black,
                        width: 2),
                  ),
                ),
              ),
              MyIconButton(
                  onPressed: () {
                    if (hideNoteInAnimeDetail) {
                      // 原先隐藏，则设置为false，表示显示
                      SPUtil.setBool("hideNoteInAnimeDetail", false);
                      hideNoteInAnimeDetail = false;
                      showToast("笔记已展开");
                    } else {
                      SPUtil.setBool("hideNoteInAnimeDetail", true);
                      hideNoteInAnimeDetail = true;
                      showToast("笔记已隐藏");
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
            child: InkWell(
              // autofocus仅仅改变的是背景色
              // autofocus: cur ? true : false,
              onTap: () {
                widget.animeController.currentStartEpisodeNumber =
                    startEpisodeNumber;
                SPUtil.setInt("${_anime.animeId}-currentStartEpisodeNumber",
                    widget.animeController.currentStartEpisodeNumber);
                Navigator.of(context).pop();
                // 获取集数据
                widget.animeController.loadEpisode();
              },
              child: Center(
                child: Text(
                  _getEpisodeRangeStr((startEpisodeNumber)),
                  style: TextStyle(
                    color: cur
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).unselectedWidgetColor,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ));
        }
        return items;
      }(),
    );
  }

  _buildEpisodeTile(int episodeIndex) {
    var episode = _episodes[episodeIndex];
    return EpisodeItemAutoLoadNote(
      animeController: widget.animeController,
      episode: episode,
      episodeIndex: episodeIndex,
      hideNote: hideNoteInAnimeDetail,
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
              textScaleFactor: AppTheme.tinyScaleFactor),
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

  void _dialogSelectReviewNumber() {
    dialogSelectUint(context, "选择第几次观看",
            initialValue: _anime.reviewNumber, minValue: 1, maxValue: 99)
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
