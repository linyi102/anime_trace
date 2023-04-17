import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_grid_view.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/common_tab_bar.dart';

import 'package:flutter_test_future/controllers/anime_display_controller.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/params/anime_sort_cond.dart';
import 'package:flutter_test_future/pages/anime_collection/checklist_controller.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_collection/db_anime_search.dart';
import 'package:flutter_test_future/pages/settings/anime_display_setting.dart';
import 'package:flutter_test_future/pages/settings/backup_restore.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:get/get.dart';
import 'package:flutter_test_future/utils/log.dart';

class AnimeListPage extends StatefulWidget {
  const AnimeListPage({Key? key}) : super(key: key);

  @override
  _AnimeListPageState createState() => _AnimeListPageState();
}

class _AnimeListPageState extends State<AnimeListPage> {
  final checklistController = ChecklistController.to;
  List<String> get tags => checklistController.tags;
  List<int> get animeCntPerTag => checklistController.animeCntPerTag;
  List<List<Anime>> get animesInTag => checklistController.animesInTag;
  List<int> get pageIndexList => checklistController.pageIndexList;

  TabController? get _tabController => checklistController.tabController;
  List<ScrollController> get _scrollControllers =>
      checklistController.scrollControllers;

  List<Anime> get selectedAnimes => checklistController.selectedAnimes;
  bool get multiSelected => checklistController.multi;

  AnimeSortCond get animeSortCond => checklistController.animeSortCond;

  // 数据加载
  bool get loadOk => checklistController.loadOk;
  int get pageSize => checklistController.pageSize;

  final AnimeDisplayController _animeDisplayController = Get.find();

  @override
  void initState() {
    super.initState();
    checklistController.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // 不生效的原因可能是因为被其他的WillPopScope监听到了
      onWillPop: () async {
        if (checklistController.multi) {
          checklistController.quitMulti();
          return false;
        }
        return true;
      },
      child: GetBuilder(
        init: checklistController,
        builder: (_) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          // 仅在第一次加载(animeCntPerTag为空)时才显示空白，之后切换到该页面时先显示旧数据
          // 然后再通过_loadData覆盖掉旧数据
          child: !loadOk && animeCntPerTag.isEmpty
              ? _waitDataScaffold()
              : Scaffold(
                  // key: UniqueKey(), // 加载这里会导致多选每次点击都会有动画，所以值需要在_waitDataScaffold中加就可以了
                  appBar: AppBar(
                    title: Text(
                      multiSelected ? "${selectedAnimes.length}" : "动漫",
                    ),
                    leading: multiSelected
                        ? IconButton(
                            onPressed: () => checklistController.quitMulti(),
                            icon: const Icon(Icons.close))
                        : null,
                    actions:
                        multiSelected ? _getActionsOnMulti() : _getActions(),
                    bottom: CommonBottomTabBar(
                      tabs: _buildTagAndAnimeCnt(),
                      tabController: _tabController,
                      isScrollable: true,
                    ),
                  ),
                  body: TabBarView(
                    controller: _tabController,
                    children: _getAnimesPlus(),
                  ),
                ),
        ),
      ),
    );
  }

  List<Widget> _getActions() {
    List<Widget> actions = [];

    actions.add(IconButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text("云端数据"),
                automaticallyImplyLeading: false,
                actions: [
                  Center(
                    child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const BackupAndRestorePage()));
                        },
                        child: const Text("进入完整页面")),
                  ),
                  // IconButton(
                  //     onPressed: () {}, icon: const Icon(Icons.chevron_right))
                ],
              ),
              body: const BackupAndRestorePage(fromHome: true)),
        );
      },
      icon: const Icon(Icons.cloud_outlined),
      tooltip: "云端数据",
    ));
    actions.add(IconButton(
      onPressed: () {
        showModalBottomSheet(
            context: context,
            builder: (context) => AnimesDisplaySetting(
                  showAppBar: false,
                  sortPage: _buildSortPage(dialog: false),
                ));
      },
      icon: const Icon(Icons.filter_list),
      tooltip: "动漫排序",
    ));
    actions.add(IconButton(
      onPressed: () async {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return const DbAnimeSearchPage();
            },
          ),
        ).then((value) {
          Log.info("更新在搜索页面里进行的修改");
          checklistController.loadAnimes();
        });
      },
      icon: const Icon(Icons.search),
      tooltip: "搜索动漫",
    ));
    return actions;
  }

  StatefulBuilder _buildSortPage({bool dialog = true}) {
    return StatefulBuilder(
      builder: (context, setState) {
        List<Widget> sortCondList = [];

        Widget checkBox = animeSortCond.desc
            ? Icon(Icons.check_box_outlined,
                color: Theme.of(context).primaryColor)
            : const Icon(Icons.check_box_outline_blank);

        sortCondList.add(ListTile(
          title: const Text("降序"),
          leading: checkBox,
          onTap: () {
            animeSortCond.desc = !animeSortCond.desc;
            SPUtil.setBool("AnimeSortCondDesc", animeSortCond.desc);
            setState(() {}); // 更新对话框里的状态
            // 改变排序时，需要滚动到顶部，否则会加载很多页
            _scrollControllers[_tabController!.index].jumpTo(0);
            checklistController.loadAnimes();
          },
        ));

        sortCondList.add(const Divider());

        for (int i = 0; i < AnimeSortCond.sortConds.length; ++i) {
          var sortCondItem = AnimeSortCond.sortConds[i];
          bool isChecked = animeSortCond.specSortColumnIdx == i;

          Widget radio = isChecked
              ? Icon(Icons.radio_button_checked,
                  color: Theme.of(context).primaryColor)
              : const Icon(Icons.radio_button_off);

          sortCondList.add(ListTile(
            title: Text(sortCondItem.showName),
            leading: radio,
            onTap: () {
              // 不相等时才设置
              if (animeSortCond.specSortColumnIdx != i) {
                animeSortCond.specSortColumnIdx = i;
                SPUtil.setInt("AnimeSortCondSpecSortColumnIdx", i);
                setState(() {}); // 更新对话框里的状态
                // 改变排序时，需要滚动到顶部，否则会加载很多页
                _scrollControllers[_tabController!.index].jumpTo(0);
                checklistController.loadAnimes();
              }
            },
          ));
        }

        Widget body =
            SingleChildScrollView(child: Column(children: sortCondList));
        if (dialog) {
          return AlertDialog(title: const Text("动漫排序"), content: body);
        } else {
          return body;
        }
      },
    );
  }

  List<Widget> _getAnimesPlus() {
    List<Widget> list = [];
    for (int checklistIdx = 0;
        checklistIdx < _scrollControllers.length;
        ++checklistIdx) {
      list.add(
        Scrollbar(
          controller: _scrollControllers[checklistIdx],
          child: Stack(children: [
            Obx(() => _animeDisplayController.displayList.value
                ? _getAnimeListView(checklistIdx)
                : _getAnimeGridView(checklistIdx)),
            // 一定要叠放在ListView上面，否则点击按钮没有反应
            _buildBottomButton(checklistIdx),
          ]),
        ),
      );
    }
    return list;
  }

  _getAnimeGridView(int checklistIdx) {
    return AnimeGridView(
        animes: animesInTag[checklistIdx],
        tagIdx: checklistIdx,
        showProgressBar: true,
        loadMore: (int tagIdx, int animeIdx) {
          _loadExtraData(tagIdx, animeIdx);
        },
        scrollController: _scrollControllers[checklistIdx],
        onClick: (Anime anime) {
          onPress(anime);
        },
        onLongClick: (Anime anime) {
          onLongPress(anime);
        },
        isSelected: (int animeIdx) {
          return selectedAnimes.contains(animesInTag[checklistIdx][animeIdx]);
        });
  }

  ListView _getAnimeListView(int tagIdx) {
    return ListView.builder(
      controller: _scrollControllers[tagIdx],
      itemCount: animesInTag[tagIdx].length,
      // itemCount: _animeCntPerTag[i], // 假装先有这么多，容易导致越界(虽然没啥影响)，但还是不用了吧
      itemBuilder: (BuildContext context, int animeIdx) {
        _loadExtraData(tagIdx, animeIdx);

        // Log.info("$index");
        // return AnimeItem(animesInTag[i][index]);
        Anime anime = animesInTag[tagIdx][animeIdx];
        return ListTile(
          selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.25),
          selected: selectedAnimes.contains(anime),
          title: Text(
            anime.animeName,
            overflow: TextOverflow.ellipsis, // 避免名字过长，导致显示多行
          ),
          leading: Obx(() => AnimeListCover(
                anime,
                showReviewNumber:
                    _animeDisplayController.showReviewNumber.value,
                reviewNumber: anime.reviewNumber,
              )),
          trailing: Text("${anime.checkedEpisodeCnt}/${anime.animeEpisodeCnt}",
              textScaleFactor: 0.95),
          onTap: () => onPress(anime),
          onLongPress: () => onLongPress(anime),
        );
      },
    );
  }

  void _loadExtraData(i, index) {
    // Log.info("index=$index");
    // 直接使用index会导致重复请求
    // 增加pageIndex变量，每当index增加到pageSize*pageIndex，就开始请求一页数据
    // 例：最开始，pageIndex=1，有pageSize=50个数据，当index到达50(50*1)时，会再次请求50个数据
    // 当到达100(50*2)时，会再次请求50个数据
    if (index + 10 == pageSize * (pageIndexList[i])) {
      // +10提前请求
      pageIndexList[i]++;
      Log.info("再次请求$pageSize个数据");
      Future(() {
        return SqliteUtil.getAllAnimeBytagName(
            tags[i], animesInTag[i].length, pageSize,
            animeSortCond: animeSortCond);
      }).then((value) {
        Log.info("请求结束");
        animesInTag[i].addAll(value);
        Log.info("添加并更新状态，animesInTag[$i].length=${animesInTag[i].length}");
        setState(() {});
      });
    }
  }

  void onPress(Anime anime) {
    // 多选
    if (multiSelected) {
      if (selectedAnimes.contains(anime)) {
        Log.info("[多选模式]移除anime=${anime.animeName}");
        selectedAnimes.remove(anime); // 选过，再选就会取消
        // 如果取消后一个都没选，就自动退出多选状态
        if (selectedAnimes.isEmpty) {
          checklistController.multi = false;
        }
      } else {
        Log.info("[多选模式]添加anime=${anime.animeName}");
        selectedAnimes.add(anime);
      }
      setState(() {});
      return;
    } else {
      _enterPageAnimeDetail(anime);
    }
  }

  void onLongPress(Anime anime) {
    // 非多选状态下才需要进入多选状态
    if (multiSelected == false) {
      checklistController.multi = true;
      selectedAnimes.add(anime);
      Log.info("[多选模式]添加anime=${anime.animeName}");
      setState(() {}); // 添加操作按钮
    } else {
      // 多选模式下，应提供范围选择
    }
  }

  void _enterPageAnimeDetail(Anime anime) {
    // 要想添加Hero动画，需要使用MaterialPageRoute
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return AnimeDetailPage(anime);
        },
      ),
    ).then((value) async {
      // 根据传回的动漫id获取最新的更新进度以及清单
      Anime newAnime = value;
      if (!newAnime.isCollected()) {
        // 取消收藏
        for (int tagIndex = 0; tagIndex < tags.length; ++tagIndex) {
          int findIndex = animesInTag[tagIndex]
              .indexWhere((element) => element.animeId == anime.animeId);
          if (findIndex != -1) {
            animesInTag[tagIndex].removeAt(findIndex);
            animeCntPerTag[tagIndex]--;
            break;
          }
        }
        setState(() {});
        return;
      }
      newAnime = await SqliteUtil.getAnimeByAnimeId(newAnime.animeId);

      // 找到并更新旧动漫
      for (int tagIndex = 0; tagIndex < tags.length; ++tagIndex) {
        int findIndex = animesInTag[tagIndex]
            .indexWhere((element) => element.animeId == newAnime.animeId);
        if (findIndex != -1) {
          // 清单改变，则移动到新的清单组
          Anime oldAnime = animesInTag[tagIndex][findIndex];
          if (oldAnime.tagName != newAnime.tagName) {
            animesInTag[tagIndex].removeAt(findIndex);
            int newTagIndex =
                tags.indexWhere((element) => element == newAnime.tagName);
            animesInTag[newTagIndex].insert(0, newAnime); // 插到最前面
            // 还要改变清单的数量
            animeCntPerTag[tagIndex]--;
            animeCntPerTag[newTagIndex]++;
          } else {
            // 清单没变，简单改下进度
            animesInTag[tagIndex][findIndex] = newAnime;
          }
          break;
        }
      }
      setState(() {});
    });
  }

  Scaffold _waitDataScaffold() {
    return Scaffold(
        key: UniqueKey(), // 保证被AnimatedSwitcher视为不同的控件
        appBar: AppBar(
            title: const Text(
          "动漫",
        )
            // actions: _getActions(),
            ));
  }

  void _dialogModifyTag(String defaultTagName) {
    List<Widget> radioList = [];
    for (int i = 0; i < tags.length; ++i) {
      radioList.add(
        ListTile(
          title: Text(tags[i]),
          leading: tags[i] == defaultTagName
              ? Icon(
                  Icons.radio_button_on_outlined,
                  color: Theme.of(context).primaryColor,
                )
              : const Icon(
                  Icons.radio_button_off_outlined,
                ),
          onTap: () {
            // 先找到原来清单对应的下标
            int oldTagindex = tags.indexOf(defaultTagName);
            int newTagindex = i;

            for (var anime in selectedAnimes) {
              animesInTag[oldTagindex]
                  .removeWhere((element) => element.animeId == anime.animeId);
              animesInTag[newTagindex].insert(0, anime);
              AnimeDao.updateTagByAnimeId(anime.animeId, tags[newTagindex]);
            }
            // 同时修改清单数量
            int modifiedCnt = selectedAnimes.length;
            animeCntPerTag[oldTagindex] -= modifiedCnt;
            animeCntPerTag[newTagindex] += modifiedCnt;
            checklistController.quitMulti();
            Navigator.pop(context);
          },
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text("选择清单"),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: radioList,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTagAndAnimeCnt() {
    List<Widget> list = [];
    for (int i = 0; i < tags.length; ++i) {
      list.add(Tab(
          child: Obx(
        () => _animeDisplayController.showAnimeCntAfterTag.value
            // 样式1：清单名(数量)
            // ? Text("${tags[i]} (${animeCntPerTag[i]})",
            //     textScaleFactor: AppTheme.smallScaleFactor)

            // 样式2：清单名紧跟缩小的数量
            ? Text.rich(TextSpan(children: [
                WidgetSpan(
                    child: Text(
                  tags[i],
                  // textScaleFactor: AppTheme.smallScaleFactor,
                  style: Theme.of(context).textTheme.bodyMedium,
                )),
                WidgetSpan(
                    child: Opacity(
                  opacity: 1.0, // 候选：0.8
                  child: Text(
                    animeCntPerTag[i].toString(),
                    // textScaleFactor: AppTheme.tinyScaleFactor,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )),
              ]))
            : Text(tags[i], textScaleFactor: AppTheme.smallScaleFactor),
      )));
    }
    return list;
  }

  _buildBottomButton(int checklistIdx) {
    return !multiSelected
        ? Container()
        : Container(
            alignment: Alignment.bottomCenter,
            child: Card(
              elevation: 8,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(50))),
              // 圆角
              clipBehavior: Clip.antiAlias,
              // 设置抗锯齿，实现圆角背景
              margin: const EdgeInsets.fromLTRB(80, 20, 80, 20),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        _dialogModifyTag(tags[checklistIdx]);
                      },
                      icon: const Icon(Icons.checklist),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: () => _dialogDeleteAnime(checklistIdx),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  _dialogDeleteAnime(int checklistIdx) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确定取消收藏吗？"),
        content: const Text("这将会删除所有相关记录！"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);

                for (var anime in checklistController.selectedAnimes) {
                  checklistController.animesInTag[checklistIdx].removeWhere(
                      (element) => element.animeId == anime.animeId);
                  AnimeDao.deleteAnimeByAnimeId(anime.animeId);
                }
                animeCntPerTag[checklistIdx] -=
                    checklistController.selectedAnimes.length;
                checklistController.quitMulti();
              },
              child: Text(
                "确定",
                style: TextStyle(color: Theme.of(context).errorColor),
              ))
        ],
      ),
    );
  }

  _getActionsOnMulti() {
    List<Widget> actions = [
      // IconButton(
      //     onPressed: () {
      //       if (checklistController.tabController == null) return;

      //       int checklistIdx = checklistController.tabController!.index;
      //       checklistController.selectedAnimes.clear();
      //       checklistController.selectedAnimes
      //           .addAll(animesInTag[checklistIdx]);
      //       setState(() {});
      //       // 缺点：全选后修改菜单，会导致无法加载下一页
      //     },
      //     icon: const Icon(Icons.select_all))
    ];
    return actions;
  }
}
