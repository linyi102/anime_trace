import 'package:flutter/material.dart';
import 'package:flutter_tab_indicator_styler/flutter_tab_indicator_styler.dart';
import 'package:flutter_test_future/dao/note_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/models/note_filter.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/components/note_img_grid.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/pages/modules/note_edit.dart';
import 'package:flutter_test_future/pages/settings/image_path_setting.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:fluttericon/entypo_icons.dart';

import '../../models/params/page_params.dart';
import '../../utils/sp_util.dart';
import '../../utils/sqlite_util.dart';
import '../../utils/time_show_util.dart';

class NoteListPage extends StatefulWidget {
  const NoteListPage({Key? key}) : super(key: key);

  @override
  _NoteListPageState createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage>
    with SingleTickerProviderStateMixin {
  // tab
  late TabController _tabController;
  final List<String> _navs = ["笔记", "评价"];

  // 笔记
  bool loadEpisodeNoteOk = false;
  NoteFilter noteFilter = NoteFilter();
  List<Note> episodeNotes = [];
  PageParams episodeNotePageParams = PageParams(pageSize: 20, pageIndex: 1);
  final ScrollController _noteScrollController = ScrollController();

  // 评价
  bool loadRateNodeOk = false;
  List<Note> rateNotes = [];
  PageParams rateNotePageParams = PageParams(pageSize: 5, pageIndex: 1);
  final ScrollController _rateScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 顶部tab控制器
    _tabController = TabController(
      initialIndex: SPUtil.getInt("lastNavIndexInNoteListPageNav",
          defaultValue: 0), // 设置初始index
      length: _navs.length,
      vsync: this,
    );
    // 添加监听器，记录最后一次的topTab的index
    _tabController.addListener(() {
      // debugPrint("切换tab，tab.index=${_tabController.index}"); // doubt win端发现会连续输出两次
      if (_tabController.index == _tabController.animation!.value) {
        SPUtil.setInt("lastNavIndexInNoteListPageNav", _tabController.index);
      }
      setState(() {});
    });

    _loadEpisodeNoteData();
    _loadRateNoteData();
  }

  void _loadData() {
    if (_tabController.index == 0) {
      _loadEpisodeNoteData();
    } else {
      _loadRateNoteData();
    }
  }

  void _loadMoreData(index) {
    if (_tabController.index == 0) {
      _loadMoreEpisodeNoteData(index);
    } else {
      _loadMoreRateNoteData(index);
    }
  }

  @override
  void dispose() {
    //为了避免内存泄露，需要调用.dispose
    _noteScrollController.dispose();
    _rateScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadEpisodeNoteData() {
    loadEpisodeNoteOk = false;
    episodeNotePageParams.resetPageIndex();
    Future(() {
      debugPrint("note_list_page: 开始加载数据");
      // return SqliteUtil.getAllNotesByTableHistory();
      return NoteDao.getAllNotesByTableNoteAndKeyword(
          0, episodeNotePageParams.pageSize, noteFilter);
    }).then((value) {
      episodeNotes = value;
      loadEpisodeNoteOk = true;
      debugPrint("note_list_page: 数据加载完成");
      debugPrint("当前笔记数量(不包括空笔记)：${episodeNotes.length}");
      setState(() {});
    });
  }

  void _loadRateNoteData() {
    loadRateNodeOk = false;
    rateNotePageParams.resetPageIndex();

    NoteDao.getRateNotes(pageParams: rateNotePageParams).then((value) {
      rateNotes = value;
      loadRateNodeOk = true;
      setState(() {});
      debugPrint("共找到${rateNotes.length}条评价笔记");
    });
  }

  void _loadMoreEpisodeNoteData(index) {
    if (index + 5 ==
        episodeNotePageParams.pageSize * episodeNotePageParams.pageIndex) {
      episodeNotePageParams.pageIndex++;
      debugPrint("再次请求${episodeNotePageParams.pageSize}个数据");
      Future(() {
        return NoteDao.getAllNotesByTableNoteAndKeyword(episodeNotes.length,
            episodeNotePageParams.pageSize, noteFilter); // 偏移量为当前页面显示的数量
      }).then((value) {
        debugPrint("请求结束");
        episodeNotes.addAll(value);
        debugPrint("添加并更新状态，episodeNotes.length=${episodeNotes.length}");
        setState(() {});
      });
    }
  }

  void _loadMoreRateNoteData(index) {
    if (index + 5 ==
        rateNotePageParams.pageSize * rateNotePageParams.pageIndex) {
      rateNotePageParams.pageIndex++;
      debugPrint("再次请求${rateNotePageParams.pageSize}个数据");
      Future(() {
        return NoteDao.getRateNotes(pageParams: rateNotePageParams);
      }).then((value) {
        debugPrint("请求结束");
        rateNotes.addAll(value);
        debugPrint("rateNotes.length=${rateNotes.length}");
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtil.getScaffoldBackgroundColor(),
      appBar: AppBar(
        title: const Text(
          "笔记",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: _buildActions(),
        bottom: PreferredSize(
          // 默认情况下，要将标签栏与相同的标题栏高度对齐，可以使用常量kToolbarHeight
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Material(
            color: ThemeUtil.getAppBarBackgroundColor(),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                tabs: _buildTabs(),
                controller: _tabController,
                // 居中，而不是靠左下
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                // 标签可以滑动，避免拥挤
                isScrollable: true,
                labelPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                // 指示器长短和标签一样
                indicatorSize: TabBarIndicatorSize.label,
                // 第三方指示器样式
                indicator: MaterialIndicator(
                    color: ThemeUtil.getPrimaryColor(),
                    paintingStyle: PaintingStyle.fill),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            child: loadEpisodeNoteOk
                ? Scrollbar(
                    controller: _noteScrollController,
                    child: _buildEpisodeNotes())
                : const Center(child: RefreshProgressIndicator()),
            onRefresh: () async {
              _loadData();
            },
          ),
          RefreshIndicator(
            child: loadEpisodeNoteOk
                ? Scrollbar(
                    controller: _rateScrollController, child: _buildRateNotes())
                : const Center(child: RefreshProgressIndicator()),
            onRefresh: () async {
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    var animeNameController = TextEditingController();
    var noteContentController = TextEditingController();
    return [
      // 只有笔记tab才提供搜索
      if (_tabController.index == 0)
        IconButton(
            tooltip: "搜索",
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("搜索"),
                      content: SingleChildScrollView(
                        child: Column(
                          children: [
                            TextField(
                              controller: animeNameController
                                ..text = noteFilter.animeNameKeyword,
                              decoration: InputDecoration(
                                  labelText: "动漫关键字",
                                  border: InputBorder.none,
                                  suffixIcon: IconButton(
                                      onPressed: () {
                                        animeNameController.text = "";
                                      },
                                      icon: const Icon(Icons.close),
                                      iconSize: 18)),
                            ),
                            TextField(
                              controller: noteContentController
                                ..text = noteFilter.noteContentKeyword,
                              decoration: InputDecoration(
                                  labelText: "笔记关键字",
                                  border: InputBorder.none,
                                  suffixIcon: IconButton(
                                      onPressed: () {
                                        noteContentController.text = "";
                                      },
                                      icon: const Icon(Icons.close),
                                      iconSize: 18)),
                            )
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("取消")),
                        ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              noteFilter.animeNameKeyword =
                                  animeNameController.text;
                              noteFilter.noteContentKeyword =
                                  noteContentController.text;
                              _loadEpisodeNoteData();
                              _noteScrollController.jumpTo(_noteScrollController
                                  .position.minScrollExtent);
                            },
                            child: const Text("搜索")),
                      ],
                    );
                  });
            },
            icon: const Icon(Entypo.search)),
      PopupMenuButton(
        icon: const Icon(Icons.more_vert),
        offset: const Offset(0, 50),
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem(
              padding: const EdgeInsets.all(0),
              child: ListTile(
                title: const Text("图片设置"),
                leading: const Icon(Icons.image_outlined),
                style: ListTileStyle.drawer,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, FadeRoute(
                    builder: (context) {
                      return const ImagePathSetting();
                    },
                  )).then((dirChanged) {
                    if (dirChanged) {
                      debugPrint("修改了图片目录，更新状态");
                      setState(() {});
                    }
                  });
                },
              ),
            ),
          ];
        },
      )
    ];
  }

  _buildRateNotes() {
    return episodeNotes.isEmpty
        ? emptyDataHint("什么都没有")
        : ListView.builder(
            controller: _rateScrollController,
            itemCount: rateNotes.length,
            itemBuilder: (BuildContext context, int index) {
              // debugPrint("index=$index");
              _loadMoreData(index);

              return Container(
                padding: const EdgeInsets.only(top: 5),
                child: Card(
                  elevation: 0,
                  child: MaterialButton(
                    elevation: 0,
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      Navigator.of(context).push(
                        FadeRoute(
                          builder: (context) {
                            return NoteEdit(rateNotes[index]);
                          },
                        ),
                      ).then((value) {
                        // 更新笔记
                        rateNotes[index] = value;
                        setState(() {});
                      });
                    },
                    child: Flex(
                      direction: Axis.vertical,
                      children: [
                        // 动漫行
                        _buildAnimeListTile(rateNotes[index]),
                        // 笔记内容
                        _buildNote(rateNotes[index]),
                        // 笔记图片
                        NoteImgGrid(
                            relativeLocalImages:
                                rateNotes[index].relativeLocalImages),
                        // 显示日期和操作
                        _buildCreateTimeAndMoreAction(rateNotes[index])
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }

  _buildEpisodeNotes() {
    return episodeNotes.isEmpty
        ? emptyDataHint("什么都没有", toastMsg: "点击已完成的集即可添加笔记")
        : ListView.builder(
            controller: _noteScrollController,
            itemCount: episodeNotes.length,
            itemBuilder: (BuildContext context, int index) {
              _loadMoreData(index);

              return Container(
                padding: const EdgeInsets.only(top: 5),
                child: Card(
                  elevation: 0,
                  child: MaterialButton(
                    elevation: 0,
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      Navigator.of(context).push(
                        // MaterialPageRoute(
                        //   builder: (context) => EpisodeNoteSF(episodeNotes[index]),
                        // ),
                        FadeRoute(
                          builder: (context) {
                            return NoteEdit(episodeNotes[index]);
                          },
                        ),
                      ).then((value) {
                        // 如果返回的笔记id为0，则说明已经从笔记列表页进入的动漫详细页删除了动漫，因此需要根据动漫id删除所有相关笔记
                        Note newEpisodeNote = value;
                        debugPrint(
                            "newEpisodeNote.anime.animeId=${newEpisodeNote.anime.animeId}");
                        if (newEpisodeNote.episodeNoteId == 0) {
                          episodeNotes.removeWhere((element) =>
                              element.anime.animeId ==
                              newEpisodeNote.anime.animeId);
                        } else {
                          episodeNotes[index] = newEpisodeNote; // 更新修改
                        }
                        setState(() {});
                      });
                    },
                    child: Flex(
                      direction: Axis.vertical,
                      children: [
                        // 动漫行
                        _buildAnimeListTile(episodeNotes[index]),
                        // 笔记内容
                        _buildNote(episodeNotes[index]),
                        // 笔记图片
                        NoteImgGrid(
                            relativeLocalImages:
                                episodeNotes[index].relativeLocalImages),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }

  _enterAnimeDetail(Anime anime) {
    Navigator.of(context)
        .push(
      FadeRoute(
        transitionDuration: const Duration(milliseconds: 200),
        builder: (context) {
          return AnimeDetailPlus(anime);
        },
      ),
    )
        .then((value) {
      // _loadData(); // 会导致重新请求数据从而覆盖episodeNotes，而返回时应该要恢复到原来的位置
      Anime anime = value;
      // 如果animeId为0，说明进入动漫详细页后删除了动漫，需要从笔记列表中删除相关笔记
      if (!anime.isCollected()) {
        episodeNotes
            .removeWhere((element) => element.anime.animeId == anime.animeId);
      }
      setState(() {});
    });
  }

  _buildAnimeListTile(Note note) {
    bool isRateNote = note.episode.number == 0;

    return ListTile(
      // style: ListTileStyle.drawer,
      // dense: true,
      leading: GestureDetector(
        onTap: () {
          _enterAnimeDetail(note.anime);
        },
        child: AnimeListCover(
          note.anime,
          showReviewNumber: true,
          reviewNumber: note.episode.reviewNumber,
        ),
      ),
      trailing: IconButton(
          onPressed: () {
            Navigator.of(context).push(
              FadeRoute(
                builder: (context) {
                  return NoteEdit(note);
                },
              ),
            ).then((value) {
              note = value; // 更新修改
              setState(() {});
            });
          },
          // icon: const Icon(Icons.more_vert_rounded)),
          icon:
              Icon(Icons.navigate_next, color: ThemeUtil.getCommonIconColor())),
      title: GestureDetector(
        onTap: () => _enterAnimeDetail(note.anime),
        child: Text(
          note.anime.animeName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textScaleFactor: ThemeUtil.smallScaleFactor,
          // textAlign: TextAlign.right,
        ),
      ),
      subtitle: isRateNote
          ? null
          : GestureDetector(
              onTap: () => _enterAnimeDetail(note.anime),
              child: Text(
                  "第 ${note.episode.number} 集 ${note.episode.getDate()}",
                  textScaleFactor: ThemeUtil.tinyScaleFactor)),
    );
  }

  _buildNote(Note note) {
    if (note.noteContent.isEmpty) return Container();
    return ListTile(
      title: Text(
        note.noteContent,
        maxLines: 10,
        overflow: TextOverflow.ellipsis,
        style: ThemeUtil.getNoteTextStyle(),
      ),
      style: ListTileStyle.drawer,
    );
  }

  _buildTabs() {
    return _navs
        .map((nav) =>
            Tab(child: Text(nav, textScaleFactor: ThemeUtil.smallScaleFactor)))
        .toList();
  }

  _buildCreateTimeAndMoreAction(Note note) {
    String timeStr = TimeShowUtil.getHumanReadableDateTimeStr(note.createTime);
    timeStr = timeStr.isEmpty ? "" : "创建于 $timeStr";

    return ListTile(
        style: ListTileStyle.drawer,
        title: Text(
          timeStr,
          style: TextStyle(
              fontWeight: FontWeight.normal,
              color: ThemeUtil.getCommentColor()),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_horiz),
          offset: const Offset(0, 50),
          itemBuilder: (BuildContext popUpMenuContext) {
            return [
              PopupMenuItem(
                padding: const EdgeInsets.all(0), // 变小
                child: ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text("删除笔记"),
                  style: ListTileStyle.drawer, // 变小
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text("确定删除笔记吗？"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                Navigator.pop(popUpMenuContext);
                              },
                              child: const Text("取消"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // 关闭对话框
                                Navigator.pop(dialogContext);
                                SqliteUtil.deleteNoteById(note.episodeNoteId)
                                    .then((val) {
                                  // 关闭下拉菜单，并重新获取评价列表
                                  Navigator.pop(popUpMenuContext);
                                  _loadRateNoteData();
                                });
                              },
                              child: const Text("确定"),
                            )
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ];
          },
        ));
  }
}
