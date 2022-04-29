import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/episode_note.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/error_image_builder.dart';
import 'package:flutter_test_future/components/image_grid_item.dart';
import 'package:flutter_test_future/components/image_grid_view.dart';
import 'package:flutter_test_future/components/select_tag_dialog.dart';
import 'package:flutter_test_future/components/select_uint_dialog.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_climb.dart';
import 'package:flutter_test_future/scaffolds/episode_note_sf.dart';
import 'package:flutter_test_future/scaffolds/tabs.dart';
import 'package:flutter_test_future/utils/climb_anime_util.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/classes/episode.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:oktoast/oktoast.dart';
import 'package:url_launcher/url_launcher.dart';

class AnimeDetailPlus extends StatefulWidget {
  final int animeId;
  const AnimeDetailPlus(this.animeId, {Key? key}) : super(key: key);

  @override
  _AnimeDetailPlusState createState() => _AnimeDetailPlusState();
}

class _AnimeDetailPlusState extends State<AnimeDetailPlus> {
  late Anime _anime;
  List<Episode> _episodes = [];
  bool _loadOk = false;
  List<EpisodeNote> episodeNotes = [];
  late int reviewNumber;
  List<bool> _expandNotes = [];

  FocusNode blankFocusNode = FocusNode(); // 空白焦点
  FocusNode animeNameFocusNode = FocusNode(); // 动漫名字输入框焦点
  // FocusNode descFocusNode = FocusNode(); // 描述输入框焦点

  // 多选
  Map<int, bool> mapSelected = {};
  bool multiSelected = false;
  Color multiSelectedColor = Colors.blueAccent.withOpacity(0.25);

  bool hideNoteInAnimeDetail =
      SPUtil.getBool("hideNoteInAnimeDetail", defaultValue: false);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    // _loadOk = false; // 保证加载n刷的数据时显示等待页面
    Future(() {
      return SqliteUtil.getAnimeByAnimeId(widget.animeId); // 一定要return，value才有值
    }).then((value) async {
      if (!_loadOk) {
        // 刚进入页面才会设置为最大回顾号，否则增加回顾号又会覆盖成最大的
        reviewNumber = await SqliteUtil.getMaxReviewNumberByAnimeId(
            widget.animeId); // 获取最大回顾号
      }
      _anime = value;
      debugPrint(value.toString());
      _episodes = await SqliteUtil.getEpisodeHistoryByAnimeIdAndReviewNumber(
          _anime, reviewNumber);
      _sortEpisodes(SPUtil.getString("episodeSortMethod",
          defaultValue: sortMethods[0])); // 排序，默认升序，兼容旧版本

      bool expandNote = SPUtil.getBool("hideNoteInAnimeDetail");
      for (int i = 0; i < _anime.animeEpisodeCnt; ++i) {
        // debugPrint(expandNote.toString());
        _expandNotes.add(expandNote);
      }

      for (var episode in _episodes) {
        EpisodeNote episodeNote = EpisodeNote(
            anime: _anime,
            episode: episode,
            relativeLocalImages: [],
            imgUrls: []);
        if (episode.isChecked()) {
          // 如果该集完成了，就去获取该集笔记（内容+图片）
          episodeNote = await SqliteUtil
              .getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(
                  episodeNote);
          // debugPrint(
          //     "第${episodeNote.episode.number}集的图片数量: ${episodeNote.relativeLocalImages.length}");
        }
        // 如果是切换，则不是add，而是覆盖
        if (_loadOk) {
          int findIndex = episodeNotes.indexWhere((element) =>
              element.episode.number == episodeNote.episode.number);
          episodeNotes[findIndex] = episodeNote;
        } else {
          episodeNotes.add(episodeNote);
        }
      }
    }).then((value) {
      _loadOk = true;
      setState(() {});
    });
  }

  // 用于传回到动漫列表页
  void _refreshAnime() {
    _anime.checkedEpisodeCnt = 0;
    for (var episode in _episodes) {
      if (episode.isChecked()) _anime.checkedEpisodeCnt++;
    }
    // SqliteUtil.updateDescByAnimeId(_anime.animeId, _anime.animeDesc);
    // SqliteUtil.updateAnimeNameByAnimeId(_anime.animeId, _anime.animeName);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        debugPrint("按返回键，返回anime");
        _refreshAnime();
        // 返回的_anime用到了id(列表页面和搜索页面)和name(爬取页面)
        // 完成集数因为切换到小的回顾号会导致不是最大回顾号完成的集数，所以那些页面会通过传回的id来获取最新动漫信息
        Navigator.pop(context, _anime);
        debugPrint("返回true");
        return true;
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: !_loadOk
              ? Container(
                  key: UniqueKey(),
                )
              : Stack(children: [
                  Scrollbar(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        // 使用await后，只有当获取信息完成后，加载圈才会消失
                        await _climbAnimeInfo();
                      },
                      child: CustomScrollView(
                        slivers: [
                          SliverAppBar(
                            // floating: true,
                            // snap: true,
                            pinned: true,
                            expandedHeight: 270,
                            stretch: true,
                            flexibleSpace: FlexibleSpaceBar(
                              background: Stack(
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    child: CachedNetworkImage(
                                      imageUrl: _anime.animeCoverUrl,
                                      errorWidget: (context, url, error) {
                                        return Container(
                                          color: const Color.fromRGBO(
                                              250, 250, 250, 1.0),
                                        );
                                      },
                                      fit: BoxFit.cover,
                                      color: const Color.fromRGBO(
                                          255, 255, 255, 0.3),
                                      colorBlendMode: BlendMode.modulate,
                                    ),
                                  ),
                                  // BackdropFilter(
                                  //   filter:
                                  //       ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                                  //   child: const SizedBox(),
                                  // ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withOpacity(0.1),
                                          Colors.white.withOpacity(0.1),
                                          Colors.white.withOpacity(0.1),
                                          Colors.white.withOpacity(0.2),
                                          Colors.white.withOpacity(0.2),
                                          const Color.fromRGBO(
                                              250, 250, 250, 0.6),
                                          const Color.fromRGBO(
                                              250, 250, 250, 0.7),
                                          const Color.fromRGBO(
                                              250, 250, 250, 0.8),
                                          const Color.fromRGBO(
                                              250, 250, 250, 1.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 30),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        _showAnimeRow(),
                                      ],
                                    ),
                                  ),
                                  // 遮住背景封面细线
                                  Positioned(
                                      bottom: -5,
                                      child: Container(
                                        height: 10,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        color: const Color.fromRGBO(
                                            250, 250, 250, 1.0),
                                      ))
                                ],
                              ),
                              collapseMode: CollapseMode.parallax,
                            ),
                            leading: IconButton(
                                onPressed: () {
                                  debugPrint("按返回按钮，返回anime");
                                  _refreshAnime();
                                  Navigator.pop(context, _anime);
                                },
                                tooltip: "返回上一级",
                                icon: const Icon(Icons.arrow_back_rounded)),
                            title: !_loadOk
                                ? Container()
                                : ListTile(
                                    title: Row(
                                      children: [
                                        Text(_anime.tagName),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        const Icon(Icons.expand_more_rounded),
                                      ],
                                    ),
                                    onTap: () {
                                      _dialogSelectTag();
                                      // 不能复用该对话框，如果选择了取消收藏，则需要退回到主页，但无法实现。
                                      // dialogSelectTag(setState, context, _anime);
                                    },
                                  ),
                            actions: [
                              IconButton(
                                  onPressed: () {
                                    _climbAnimeInfo();
                                  },
                                  tooltip: "更新信息",
                                  icon: const Icon(Icons.refresh)),
                              PopupMenuButton(
                                icon: const Icon(Icons.more_vert),
                                offset: const Offset(0, 50),
                                itemBuilder: (BuildContext context) {
                                  return [
                                    PopupMenuItem(
                                      child: ListTile(
                                        title: const Text("取消收藏"),
                                        style: ListTileStyle.drawer,
                                        onTap: () {
                                          _dialogDeleteAnime();
                                        },
                                      ),
                                    ),
                                    PopupMenuItem(
                                      child: ListTile(
                                        title: const Text("访问网址"),
                                        style: ListTileStyle.drawer,
                                        onTap: () async {
                                          Uri uri;
                                          if (_anime.animeUrl.isNotEmpty) {
                                            uri = Uri.parse(_anime.animeUrl);
                                            if (!await launchUrl(uri)) {
                                              throw "Could not launch $uri";
                                            }
                                          } else {
                                            showToast("网址为空，请先迁移动漫");
                                          }
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                    PopupMenuItem(
                                      child: ListTile(
                                        title: const Text("迁移动漫"),
                                        style: ListTileStyle.drawer,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            // MaterialPageRoute(
                                            //   builder: (context) => AnimeClimb(
                                            //     animeId: _anime.animeId,
                                            //     keyword: _anime.animeName,
                                            //   ),
                                            // ),
                                            FadeRoute(
                                              builder: (context) {
                                                return AnimeClimb(
                                                  animeId: _anime.animeId,
                                                  keyword: _anime.animeName,
                                                );
                                              },
                                            ),
                                          ).then((value) {
                                            _loadData();
                                            Navigator.pop(context);
                                          });
                                        },
                                      ),
                                    ),
                                  ];
                                },
                              ),
                            ],
                          ),
                          SliverToBoxAdapter(
                            child: _displayButtonsAboutEpisode(),
                          ),
                          _showEpisode(),
                        ],
                      ),
                    ),
                  ),
                  _showBottomButton()
                ]),
        ),
      ),
    );
  }

  _showAnimeRow() {
    final imageProvider = Image.network(_anime.animeCoverUrl).image;
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: MaterialButton(
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      showImageViewer(context, imageProvider, immersive: false);
                    },
                    child: AnimeGridCover(_anime),
                  ),
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _showAnimeName(_anime.animeName),
              _showNameAnother(_anime.nameAnother),
              _showAnimeInfo(_anime.getSubTitle()),
              // _showAnimeInfo(_anime.getVariableInfo()),
              // _showAnimeInfo(_anime.getConstantInfo()),
              _showSource(ClimbAnimeUtil.getSourceByAnimeUrl(_anime.animeUrl)),
              // _displayDesc(),
            ],
          ),
        ),
        // Column(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [_showCollectIcon(_anime)],
        // ),
      ],
    );
  }

  _showAnimeName(animeName) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
      child: Text(
        animeName,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    );
  }

  _showNameAnother(String nameAnother) {
    return nameAnother.isEmpty
        ? Container()
        : Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
            child: Text(
              nameAnother,
              style: const TextStyle(color: Colors.black54),
            ),
          );
  }

  _showAnimeInfo(animeInfo) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
      child: Text(
        animeInfo,
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }

  _showSource(coverSource) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
      child: Text(
        "$coverSource",
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }

  _showCollectIcon(Anime anime) {
    return Container(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          IconButton(
              onPressed: () {
                // 不能使用，因为里面的删除动漫后找不到方法直接返回主页
                // dialogSelectTag(setState, context, anime);
                _dialogSelectTag();
              },
              icon: anime.isCollected()
                  ? const Icon(
                      Icons.favorite,
                      color: Colors.red,
                    )
                  : const Icon(Icons.favorite_border)),
          anime.isCollected() ? Text(anime.tagName) : Container()
        ],
      ),
    );
  }

  _showEpisode() {
    return SliverList(
      // SliverList 的语法糖，用于每个 item 固定高度的 List
      delegate: SliverChildBuilderDelegate(
        (context, episodeIndex) {
          // debugPrint("$episodeIndex");
          List<Widget> columnChildren = [];

          // 添加每集
          columnChildren.add(
            ListTile(
              selectedTileColor: multiSelectedColor,
              selected: mapSelected.containsKey(episodeIndex),
              selectedColor: Colors.black,
              // visualDensity: const VisualDensity(vertical: -2),
              // contentPadding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
              title: Text(
                "第 ${_episodes[episodeIndex].number} 集",
                style: TextStyle(
                  color: _episodes[episodeIndex].isChecked()
                      ? Colors.black54
                      : Colors.black,
                ),
              ),
              // subtitle: Text(_episodes[i].getDate()),
              // enabled: !_episodes[i].isChecked(), // 完成后会导致无法长按设置日期
              // style: ListTileStyle.drawer,
              trailing: Text(
                _episodes[episodeIndex].getDate(),
                style: const TextStyle(color: Colors.black54),
              ),
              leading: IconButton(
                // iconSize: 20,
                visualDensity: VisualDensity.compact, // 缩小leading
                hoverColor: Colors.transparent, // 悬停时的颜色
                highlightColor: Colors.transparent, // 长按时的颜色
                splashColor: Colors.transparent, // 点击时的颜色
                onPressed: () async {
                  if (_episodes[episodeIndex].isChecked()) {
                    _dialogRemoveDate(
                      _episodes[episodeIndex].number,
                      _episodes[episodeIndex].dateTime,
                    ); // 这个函数执行完毕后，在执行下面的setState并不会更新页面，因此需要在该函数中使用setState
                  } else {
                    String date = DateTime.now().toString();
                    SqliteUtil.insertHistoryItem(_anime.animeId,
                        _episodes[episodeIndex].number, date, reviewNumber);
                    _episodes[episodeIndex].dateTime = date;
                    // 同时插入空笔记，记得获取最新插入的id，否则进入的是笔记0，会造成修改笔记无效
                    EpisodeNote episodeNote = EpisodeNote(
                        anime: _anime,
                        episode: _episodes[episodeIndex],
                        relativeLocalImages: [],
                        imgUrls: []);

                    // 如果存在，恢复之前做的笔记。(完成该集并添加笔记后，又完成该集，需要恢复笔记)
                    episodeNotes[episodeIndex] = await SqliteUtil
                        .getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(
                            episodeNote);
                    // 不存在，则添加新笔记。因为获取笔记的函数中也实现了没有则添加新笔记，因此就不需要这个了
                    // episodeNote.episodeNoteId =
                    //     await SqliteUtil.insertEpisodeNote(episodeNote);
                    // episodeNotes[i] = episodeNote; // 更新
                    _moveToLastIfSet(episodeIndex);
                    setState(() {});
                  }
                },
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  // transitionBuilder: (Widget child, Animation<double> animation) {
                  //   //执行缩放动画
                  //   return ScaleTransition(child: child, scale: animation);
                  // },
                  child: _episodes[episodeIndex].isChecked()
                      ? Icon(
                          Icons.check_box_outlined,
                          // Icons.check_rounded,
                          color: Colors.black54,
                          key: Key("$episodeIndex"), // 不能用unique，否则同状态的按钮都会有动画
                        )
                      : const Icon(
                          Icons.check_box_outline_blank_rounded,
                          color: Colors.black54,
                        ),
                ),
              ),
              onTap: () {
                onpress(episodeIndex);
              },
              onLongPress: () async {
                // pickDate(episodeIndex);
                onLongPress(episodeIndex);
              },
            ),
          );
          // 在每一集下面添加笔记
          if (!hideNoteInAnimeDetail && _episodes[episodeIndex].isChecked()) {
            columnChildren.add(displayNote(episodeIndex, context));
          }

          // 在最后一集下面添加空白
          if (episodeIndex == _episodes.length - 1) {
            columnChildren.add(const ListTile());
            columnChildren.add(const ListTile());
          }
          return Column(
            children: columnChildren,
          );
        },
        childCount: _episodes.length,
      ),
    );
  }

  Widget displayNote(int episodeIndex, BuildContext context) {
    // 由于排序后集列表排了序，但笔记列表没有排序，会造成笔记混乱，因此显示笔记时，根据该集的编号来找到笔记
    int episodeNoteIndex = episodeNotes.indexWhere(
        (element) => element.episode.number == _episodes[episodeIndex].number);

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      child: episodeNotes[episodeNoteIndex].relativeLocalImages.isEmpty &&
              episodeNotes[episodeNoteIndex].noteContent.isEmpty
          ? Container()
          : Card(
              elevation: 0,
              child: MaterialButton(
                padding: episodeNotes[episodeNoteIndex].noteContent.isEmpty
                    ? const EdgeInsets.fromLTRB(0, 0, 0, 0)
                    : const EdgeInsets.fromLTRB(0, 10, 0, 0),
                onPressed: () {
                  Navigator.of(context).push(
                    // MaterialPageRoute(
                    //     builder: (context) =>
                    //         EpisodeNoteSF(episodeNotes[episodeIndex])),
                    FadeRoute(
                      builder: (context) {
                        return EpisodeNoteSF(episodeNotes[episodeNoteIndex]);
                      },
                    ),
                  ).then((value) {
                    episodeNotes[episodeNoteIndex] = value; // 更新修改
                    setState(() {});
                  });
                },
                child: Column(
                  children: [
                    episodeNotes[episodeNoteIndex].noteContent.isEmpty
                        ? Container()
                        : ListTile(
                            title: Text(
                              episodeNotes[episodeNoteIndex].noteContent,
                              maxLines: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ListTileStyle.drawer,
                          ),
                    episodeNotes[episodeNoteIndex].relativeLocalImages.length ==
                            1
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(5), // 圆角
                            child: Image.file(
                              File(ImageUtil.getAbsoluteImagePath(
                                  episodeNotes[episodeNoteIndex]
                                      .relativeLocalImages[0]
                                      .path)),
                              fit: BoxFit.fitHeight,
                              errorBuilder: errorImageBuilder(
                                  episodeNotes[episodeNoteIndex]
                                      .relativeLocalImages[0]
                                      .path),
                            ),
                          )
                        : showImageGridView(
                            episodeNotes[episodeNoteIndex]
                                .relativeLocalImages
                                .length,
                            (BuildContext context, int imageIndex) {
                            return ImageGridItem(
                              relativeLocalImages:
                                  episodeNotes[episodeNoteIndex]
                                      .relativeLocalImages,
                              initialIndex: imageIndex,
                            );
                          })
                  ],
                ),
              ),
            ),
    );
  }

  void pickDate(i) async {
    DateTime defaultDateTime = DateTime.now();
    if (_episodes[i].isChecked()) {
      defaultDateTime = DateTime.parse(_episodes[i].dateTime as String);
    }
    String dateTime = await _showDatePicker(defaultDateTime: defaultDateTime);

    if (dateTime.isEmpty) return; // 没有选择日期，则直接返回

    // 选择日期后，如果之前有日期，则更新。没有则直接插入
    // 注意：对于_episodes[i]，它是第_episodes[i].number集
    int episodeNumber = _episodes[i].number;
    if (_episodes[i].isChecked()) {
      SqliteUtil.updateHistoryItem(
          _anime.animeId, episodeNumber, dateTime, reviewNumber);
    } else {
      SqliteUtil.insertHistoryItem(
          _anime.animeId, episodeNumber, dateTime, reviewNumber);
    }
    // 更新页面
    setState(() {
      // 改的是i，而不是episodeNumber
      _episodes[i].dateTime = dateTime;
    });
  }

  void onpress(episodeIndex) {
    // 多选
    if (multiSelected) {
      if (mapSelected.containsKey(episodeIndex)) {
        mapSelected.remove(episodeIndex); // 选过，再选就会取消
        // 如果取消后一个都没选，就自动退出多选状态
        if (mapSelected.isEmpty) {
          multiSelected = false;
        }
      } else {
        mapSelected[episodeIndex] = true;
      }
      setState(() {});
    } else {
      FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
      if (_episodes[episodeIndex].isChecked()) {
        Navigator.of(context).push(
          // MaterialPageRoute(
          //     builder: (context) => EpisodeNoteSF(episodeNotes[i])),
          FadeRoute(
            builder: (context) {
              return EpisodeNoteSF(episodeNotes[episodeIndex]);
            },
          ),
        ).then((value) {
          episodeNotes[episodeIndex] = value; // 更新修改
          setState(() {});
        });
      }
    }
  }

  void onLongPress(index) {
    // 非多选状态下才需要进入多选状态
    if (multiSelected == false) {
      multiSelected = true;
      mapSelected[index] = true;
      setState(() {}); // 添加操作按钮
    }
  }

  Future<String> _showDatePicker({DateTime? defaultDateTime}) async {
    var picker = await showDatePicker(
        context: context,
        initialDate: defaultDateTime ?? DateTime.now(), // 没有给默认时间时，设置为今天
        firstDate: DateTime(1986),
        lastDate: DateTime(DateTime.now().year + 2),
        locale: const Locale("zh"));
    return picker == null ? "" : picker.toString();
  }

  _showBottomButton() {
    return !multiSelected
        ? Container()
        : Container(
            alignment: Alignment.bottomCenter,
            child: Card(
              elevation: 4,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15))), // 圆角
              clipBehavior: Clip.antiAlias, // 设置抗锯齿，实现圆角背景
              color: Colors.white,
              margin: const EdgeInsets.fromLTRB(50, 20, 50, 20),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        if (mapSelected.length == _episodes.length) {
                          // 全选了，点击则会取消全选
                          mapSelected.clear();
                        } else {
                          // 其他情况下，全选
                          for (int j = 0; j < _episodes.length; ++j) {
                            mapSelected[j] = true;
                          }
                        }
                        setState(() {});
                      },
                      icon: const Icon(Icons.select_all_rounded),
                      color: Colors.black,
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: () async {
                        DateTime defaultDateTime = DateTime.now();
                        String dateTime = await _showDatePicker(
                            defaultDateTime: defaultDateTime);
                        if (dateTime.isNotEmpty) {
                          mapSelected.forEach((episodeIndex, value) {
                            int episodeNumber = _episodes[episodeIndex].number;
                            if (_episodes[episodeIndex].isChecked()) {
                              SqliteUtil.updateHistoryItem(_anime.animeId,
                                  episodeNumber, dateTime, reviewNumber);
                            } else {
                              SqliteUtil.insertHistoryItem(_anime.animeId,
                                  episodeNumber, dateTime, reviewNumber);
                              // 同时插入空笔记，记得获取最新插入的id，否则进入的是笔记0，会造成修改笔记无效
                              EpisodeNote episodeNote = EpisodeNote(
                                  anime: _anime,
                                  episode: _episodes[episodeIndex],
                                  relativeLocalImages: [],
                                  imgUrls: []);

                              // 如果存在，恢复之前做的笔记。(完成该集并添加笔记后，又完成该集，需要恢复笔记)
                              () async {
                                episodeNotes[episodeIndex] = await SqliteUtil
                                    .getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(
                                        episodeNote);
                              }(); // 只让恢复笔记作为异步，如果让forEach中的函数作为异步，则可能会在改变所有时间前退出多选模式
                            }
                            _episodes[episodeIndex].dateTime = dateTime;
                          });
                        } // 遍历选中的下标
                        // 退出多选模式
                        _quitMultiSelectState();
                      },
                      icon: const Icon(Icons.date_range),
                      color: Colors.black,
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        _quitMultiSelectState();
                      },
                      icon: const Icon(Icons.exit_to_app_outlined),
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  void _quitMultiSelectState() {
    // 清空选择的动漫(注意在修改数量之后)，并消除多选状态
    multiSelected = false;
    mapSelected.clear();
    setState(() {});
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
            TextButton(
              onPressed: () {
                SqliteUtil
                    .deleteHistoryItemByAnimeIdAndEpisodeNumberAndReviewNumber(
                        _anime.animeId, episodeNumber, reviewNumber);
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

  void _dialogSelectTag() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Widget> radioList = [];
        for (int i = 0; i < tags.length; ++i) {
          radioList.add(
            ListTile(
              title: Text(tags[i]),
              leading: tags[i] == _anime.tagName
                  ? const Icon(
                      Icons.radio_button_on_outlined,
                      color: Colors.blue,
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                _anime.tagName = tags[i];
                SqliteUtil.updateTagByAnimeId(_anime.animeId, _anime.tagName);
                debugPrint("修改标签为${_anime.tagName}");
                setState(() {});
                Navigator.pop(context);
              },
            ),
          );
        }
        return AlertDialog(
          title: const Text('选择标签'),
          content: SingleChildScrollView(
            child: Column(
              children: radioList,
            ),
          ),
        );
      },
    );
  }

  List<String> sortMethods = [
    "sortByEpisodeNumberAsc",
    "sortByEpisodeNumberDesc",
    "sortByUnCheckedFront"
  ];

  List<String> sortMethodsName = ["集数升序", "集数倒序", "未完成在前"];

  void _dialogSelectSortMethod() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Widget> radioList = [];
        for (int i = 0; i < sortMethods.length; ++i) {
          radioList.add(
            ListTile(
              title: Text(sortMethodsName[i]),
              leading: sortMethods[i] == SPUtil.getString("episodeSortMethod")
                  ? const Icon(
                      Icons.radio_button_on_outlined,
                      color: Colors.blue,
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                debugPrint("修改排序方式为${sortMethods[i]}");
                _sortEpisodes(sortMethods[i]);
                setState(() {});
                Navigator.pop(context);
              },
            ),
          );
        }
        return AlertDialog(
          title: const Text('排序方式'),
          content: SingleChildScrollView(
            child: Column(
              children: radioList,
            ),
          ),
        );
      },
    );
  }

  _dialogDeleteAnime() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("警告！"),
            content: const Text("确认删除该动漫吗？"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("取消")),
              TextButton(
                  onPressed: () {
                    SqliteUtil.deleteAnimeByAnimeId(_anime.animeId);
                    // 直接返回到主页
                    Navigator.of(context).pushAndRemoveUntil(
                      // MaterialPageRoute(builder: (context) => const Tabs()),
                      FadeRoute(
                        builder: (context) {
                          return const Tabs();
                        },
                      ),
                      (route) => false,
                    ); // 返回false就没有左上角的返回按钮了
                  },
                  child: const Text(
                    "确认",
                    style: TextStyle(color: Colors.red),
                  )),
            ],
          );
        });
  }

  _displayButtonsAboutEpisode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      // direction: Axis.horizontal,
      children: [
        Row(children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: IconButton(
              onPressed: () {
                if (reviewNumber - 1 <= 0) {
                  return;
                }
                reviewNumber--;
                setState(() {});
                _loadData();
              },
              icon: const Icon(Icons.chevron_left_rounded),
            ),
          ),
          // Text("第 $reviewNumber 次观看"),
          Text("$reviewNumber"),
          IconButton(
            onPressed: () {
              reviewNumber++;
              setState(() {});
              _loadData();
            },
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ]),
        Expanded(child: Container()),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
                onPressed: () {
                  if (hideNoteInAnimeDetail) {
                    // 原先隐藏，则设置为false，表示显示
                    SPUtil.setBool("hideNoteInAnimeDetail", false);
                    hideNoteInAnimeDetail = false;
                    // 可折叠
                    for (int i = 0; i < _anime.animeEpisodeCnt; ++i) {
                      _expandNotes[i] = true;
                    }
                  } else {
                    SPUtil.setBool("hideNoteInAnimeDetail", true);
                    hideNoteInAnimeDetail = true;
                    // 可折叠
                    for (int i = 0; i < _anime.animeEpisodeCnt; ++i) {
                      _expandNotes[i] = false;
                    }
                  }
                  setState(() {});
                },
                tooltip: hideNoteInAnimeDetail ? "显示笔记" : "隐藏笔记",
                icon: hideNoteInAnimeDetail
                    ? const Icon(Icons.expand_more)
                    : const Icon(Icons.expand_less)),
            IconButton(
                onPressed: () {
                  _dialogSelectSortMethod();
                },
                tooltip: "排序方式",
                icon: const Icon(Icons.sort)),
            IconButton(
                onPressed: () {
                  // _dialogUpdateEpisodeCnt();
                  dialogSelectUint(context, "修改集数",
                          defaultValue: _anime.animeEpisodeCnt,
                          minValue: 0,
                          maxValue: 2000)
                      .then((value) {
                    if (value == null) {
                      debugPrint("未选择，直接返回");
                      return;
                    }
                    int episodeCnt = value;
                    SqliteUtil.updateEpisodeCntByAnimeId(
                        _anime.animeId, episodeCnt);

                    _anime.animeEpisodeCnt = episodeCnt;
                    // 少了就删除，多了就添加
                    var len = _episodes
                        .length; // 因为添加或删除时_episodes.length会变化，所以需要保存到一个变量中
                    if (len > episodeCnt) {
                      for (int i = 0; i < len - episodeCnt; ++i) {
                        // 还应该删除history表里的记录，否则会误判完成过的集数
                        SqliteUtil
                            .deleteHistoryItemByAnimeIdAndEpisodeNumberAndReviewNumber(
                                _anime.animeId,
                                _episodes.last.number,
                                reviewNumber);
                        // 注意顺序
                        _episodes.removeLast();
                      }
                    } else {
                      int number = _episodes.last.number;
                      for (int i = 0; i < episodeCnt - len; ++i) {
                        _episodes.add(Episode(number + i + 1, reviewNumber));
                      }
                    }
                    setState(() {});
                  });
                },
                tooltip: "更改集数",
                icon: const Icon(Icons.mode)),
          ],
        ),
      ],
    );
  }

  void _sortEpisodes(String sortMethod) {
    if (sortMethod == "sortByEpisodeNumberAsc") {
      _sortByEpisodeNumberAsc(sortMethod);
    } else if (sortMethod == "sortByEpisodeNumberDesc") {
      _sortByEpisodeNumberDesc(sortMethod);
    } else if (sortMethod == "sortByUnCheckedFront") {
      _sortByUnCheckedFront(sortMethod);
    } else {
      throw "不可能的排序方式";
    }
    SPUtil.setString("episodeSortMethod", sortMethod);
  }

  void _sortByEpisodeNumberAsc(String sortMethod) {
    _episodes.sort((a, b) {
      return a.number.compareTo(b.number);
    });
  }

  void _sortByEpisodeNumberDesc(String sortMethod) {
    _episodes.sort((a, b) {
      return b.number.compareTo(a.number);
    });
  }

  // 未完成的靠前，完成的按number升序排序
  void _sortByUnCheckedFront(String sortMethod) {
    _sortByEpisodeNumberAsc(sortMethod); // 先按number升序排序
    _episodes.sort((a, b) {
      int ac, bc;
      ac = a.isChecked() ? 1 : 0;
      bc = b.isChecked() ? 1 : 0;
      // 双方都没有完成或都完成(状态一致)时，按number升序排序
      if (a.isChecked() == b.isChecked()) {
        return a.number.compareTo(b.number);
      } else {
        // 否则未完成的靠前
        return ac.compareTo(bc);
      }
    });
  }

  // 如果设置了未完成的靠前，则完成某集后移到最后面
  void _moveToLastIfSet(int index) {
    // 先不用移到最后面吧
    // // 先移除，再添加
    // if (SPUtil.getBool("sortByUnCheckedFront")) {
    //   Episode episode = _episodes[index];
    //   _episodes.removeAt(index);
    //   _episodes.add(episode); // 不应该直接在后面添加，而是根据number插入到合适的位置。但还要注意越界什么的
    // }
  }
  // 如果取消了日期，还需要移到最前面。好麻烦...还得插入到合适的位置

  int _getEpisodeIndexByEpisodeNumber(int episodeNumber) {
    return _episodes.indexWhere((element) => element.number == episodeNumber);
  }

  Future<bool> _climbAnimeInfo() async {
    if (_anime.animeUrl.isEmpty) {
      showToast("当前动漫没有来源，请先进行迁移");
      return false;
    }
    // oldAnime、newAnime、_anime引用的是同一个对象，修改后无法比较，因此需要先让oldAnime引用深拷贝的_anime
    // 因为更新时会用到oldAnime的id、tagName、animeEpisodeCnt，所以只深拷贝这些成员
    Anime oldAnime = Anime(
        animeId: _anime.animeId,
        animeName: _anime.animeName,
        animeEpisodeCnt: _anime.animeEpisodeCnt,
        tagName: _anime.tagName);
    // 需要传入_anime，然后会修改里面的值，newAnime也会引用该对象
    Anime newAnime = await ClimbAnimeUtil.climbAnimeInfoByUrl(_anime);
    SqliteUtil.updateAnime(oldAnime, newAnime).then((value) {
      // 如果集数变大，则重新加载页面
      if (newAnime.animeEpisodeCnt > oldAnime.animeEpisodeCnt) {
        _loadData();
      }
    });
    setState(() {
      _anime = newAnime;
    });
    showToast("更新信息成功");
    return true;
  }
}
