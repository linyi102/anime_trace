import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tab_indicator_styler/flutter_tab_indicator_styler.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/controllers/anime_display_controller.dart';

import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_collection/search_db_anime.dart';
import 'package:flutter_test_future/pages/settings/anime_display_setting.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:get/get.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../../components/common_tab_bar.dart';
import '../../components/get_anime_grid_delegate.dart';
import '../../models/params/anime_sort_cond.dart';
import '../../components/anime_grid_view.dart';

class AnimeListPage extends StatefulWidget {
  const AnimeListPage({Key? key}) : super(key: key);

  @override
  _AnimeListPageState createState() => _AnimeListPageState();
}

class _AnimeListPageState extends State<AnimeListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AnimeSortCond animeSortCond = AnimeSortCond(
      specSortColumnIdx:
          SPUtil.getInt("AnimeSortCondSpecSortColumnIdx", defaultValue: 3),
      desc: SPUtil.getBool("AnimeSortCondDesc", defaultValue: true));

  // 数据加载
  bool _loadOk = false;
  List<int> pageIndexList = List.generate(tags.length, (index) => 1); // 初始页都为1
  final int _pageSize = 50;

  // 多选
  Map<int, bool> mapSelected = {};
  bool multiSelected = false;
  Color multiSelectedColor = ThemeUtil.getPrimaryColor().withOpacity(0.25);

  final List<ScrollController> _scrollControllers = [];
  final AnimeDisplayController _animeDisplayController = Get.find();

  bool useTopTab = true;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < tags.length; ++i) {
      animesInTag.add([]); // 先添加元素List，然后才能用下标访问
      _scrollControllers.add(ScrollController()); // 为每个清单提供单独的滚动控制器
    }

    _loadData();
    // 顶部tab控制器
    _tabController = TabController(
      initialIndex:
          SPUtil.getInt("last_top_tab_index", defaultValue: 0), // 设置初始index
      length: tags.length,
      vsync: this,
    );
    // 添加监听器，记录最后一次的topTab的index
    _tabController.addListener(() {
      if (_tabController.index == _tabController.animation!.value) {
        // lastTopTabIndex = _tabController.index;
        SPUtil.setInt("last_top_tab_index", _tabController.index);
        // 取消多选
        if (multiSelected) {
          _quitMultiSelectState();
        }
      }
    });
  }

  void _loadData() async {
    // 首次或重新渲染时，重置页号，就能保证之后也能加载更多数据了
    for (int i = 0; i < pageIndexList.length; ++i) {
      pageIndexList[i] = 1;
    }

    Log.info("开始加载数据");
    Future(() async {
      animeCntPerTag = await SqliteUtil.getAnimeCntPerTag();
      for (int i = 0; i < tags.length; ++i) {
        animesInTag[i] = await SqliteUtil.getAllAnimeBytagName(
            tags[i], 0, _pageSize,
            animeSortCond: animeSortCond);
        // Log.info("animesInTag[$i].length=${animesInTag[i].length}");
      }
    }).then((value) {
      Log.info("数据加载完毕");
      _loadOk = true; // 放这里啊，之前干嘛放外面...
      if (mounted) {
        setState(() {});
      } // 数据加载完毕后，再刷新页面。注意下面数据未加载完毕时，由于loadOk为false，显示的是其他页面
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (int i = 0; i < tags.length; ++i) {
      _scrollControllers[i].dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      // 仅在第一次加载(animeCntPerTag为空)时才显示空白，之后切换到该页面时先显示旧数据
      // 然后再通过_loadData覆盖掉旧数据
      child: !_loadOk && animeCntPerTag.isEmpty
          ? _waitDataScaffold()
          : Scaffold(
              // key: UniqueKey(), // 加载这里会导致多选每次点击都会有动画，所以值需要在_waitDataScaffold中加就可以了
              appBar: AppBar(
                title: Text(
                  multiSelected ? "${mapSelected.length}" : "动漫",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                leading: multiSelected
                    ? IconButton(
                        onPressed: () {
                          _quitMultiSelectState();
                        },
                        icon: const Icon(Icons.close))
                    : null,
                actions: multiSelected ? _getActionsOnMulti() : _getActions(),
                bottom: useTopTab
                    ? CommonTabBar(
                        tabs: _buildTagAndAnimeCnt(),
                        controller: _tabController,
                        isScrollable: true,
                      )
                    : null,
              ),
              body: useTopTab
                  ? TabBarView(
                      controller: _tabController,
                      children: _getAnimesPlus(),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          child: SingleChildScrollView(
                            child: Column(
                              children: tags.map((checklist) {
                                int checklistIdx = tags.indexWhere(
                                    (element) => element == checklist);
                                return ListTile(
                                  selected:
                                      _tabController.index == checklistIdx,
                                  title: Obx(
                                    () => _animeDisplayController
                                            .showAnimeCntAfterTag.value
                                        ? Text(
                                            "${tags[checklistIdx]} (${animeCntPerTag[checklistIdx]})",
                                            textScaleFactor:
                                                ThemeUtil.smallScaleFactor)
                                        : Text(tags[checklistIdx],
                                            textScaleFactor:
                                                ThemeUtil.smallScaleFactor),
                                  ),
                                  onTap: () {
                                    int checklistIdx = tags.indexWhere(
                                        (element) => element == checklist);
                                    _tabController.index = checklistIdx;
                                    setState(() {});
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        Expanded(
                          // TODO：切换左侧tab后，滚动条位置并没有恢复到之前位置，而是共用了同一个滚动条
                          child: Scrollbar(
                            controller:
                                _scrollControllers[_tabController.index],
                            child: Stack(children: [
                              Obx(() => _animeDisplayController
                                      .displayList.value
                                  ? _getAnimeListView(_tabController.index)
                                  : _getAnimeGridView(_tabController.index)),
                              // 一定要叠放在ListView上面，否则点击按钮没有反应
                              _buildBottomButton(_tabController.index),
                            ]),
                          ),
                        )
                      ],
                    ),
            ),
    );
  }

  List<Widget> _getActions() {
    List<Widget> actions = [];

    actions.add(IconButton(
      onPressed: () {
        showDialog(
            context: context,
            builder: (dialogContext) {
              return StatefulBuilder(
                builder: (context, setState) {
                  List<Widget> sortCondList = [];

                  for (int i = 0; i < AnimeSortCond.sortConds.length; ++i) {
                    var sortCondItem = AnimeSortCond.sortConds[i];
                    bool isChecked = animeSortCond.specSortColumnIdx == i;
                    sortCondList.add(ListTile(
                      title: Text(sortCondItem.showName),
                      leading: isChecked
                          ? Icon(Icons.radio_button_checked,
                              color: ThemeUtil.getPrimaryIconColor())
                          : const Icon(Icons.radio_button_off),
                      onTap: () {
                        // 不相等时才设置
                        if (animeSortCond.specSortColumnIdx != i) {
                          animeSortCond.specSortColumnIdx = i;
                          SPUtil.setInt("AnimeSortCondSpecSortColumnIdx", i);
                          setState(() {}); // 更新对话框里的状态
                          // 改变排序时，需要滚动到顶部，否则会加载很多页
                          _scrollControllers[_tabController.index].jumpTo(0);
                          _loadData();
                        }
                      },
                    ));
                  }
                  sortCondList.add(const Divider());
                  sortCondList.add(ListTile(
                    title: const Text("降序"),
                    leading: animeSortCond.desc
                        ? Icon(Icons.check_box_outlined,
                            color: ThemeUtil.getPrimaryIconColor())
                        : const Icon(Icons.check_box_outline_blank),
                    onTap: () {
                      animeSortCond.desc = !animeSortCond.desc;
                      SPUtil.setBool("AnimeSortCondDesc", animeSortCond.desc);
                      setState(() {}); // 更新对话框里的状态
                      // 改变排序时，需要滚动到顶部，否则会加载很多页
                      _scrollControllers[_tabController.index].jumpTo(0);
                      _loadData();
                    },
                  ));

                  return AlertDialog(
                    title: const Text("动漫排序"),
                    content: SingleChildScrollView(
                      child: Column(
                        children: sortCondList,
                      ),
                    ),
                  );
                },
              );
            });
      },
      icon: const Icon(Icons.filter_list),
      tooltip: "动漫排序",
    ));
    actions.add(IconButton(
      onPressed: () {
        showFlexibleBottomSheet(
            duration: const Duration(milliseconds: 200),
            minHeight: 0,
            initHeight: 0.5,
            maxHeight: 1,
            context: context,
            builder: (
              BuildContext context,
              ScrollController scrollController,
              double bottomSheetOffset,
            ) =>
                const AnimesDisplaySetting(showAppBar: false),
            isExpand: true);
      },
      icon: const Icon(Entypo.layout),
      tooltip: "外观设置",
    ));
    actions.add(IconButton(
      onPressed: () async {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return const SearchDbAnime();
            },
          ),
        ).then((value) {
          Log.info("更新在搜索页面里进行的修改");
          _loadData();
        });
      },
      icon: const Icon(Icons.search),
      tooltip: "搜索动漫",
    ));
    return actions;
  }

  List<Widget> _getAnimesPlus() {
    List<Widget> list = [];
    for (int checklistIdx = 0; checklistIdx < tags.length; ++checklistIdx) {
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
        loadMore: (int tagIdx, int animeIdx) {
          _loadExtraData(tagIdx, animeIdx);
        },
        scrollController: _scrollControllers[checklistIdx],
        onClick: (int animeIdx) {
          onPress(animeIdx, animesInTag[checklistIdx][animeIdx]);
        },
        onLongClick: (int animeIdx) {
          onLongPress(animeIdx);
        },
        isSelected: (int animeIdx) {
          return mapSelected.containsKey(animeIdx);
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
          selectedTileColor: multiSelectedColor,
          selected: mapSelected.containsKey(animeIdx),
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
          onTap: () {
            onPress(animeIdx, anime);
          },
          onLongPress: () {
            onLongPress(animeIdx);
          },
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
    if (index + 10 == _pageSize * (pageIndexList[i])) {
      // +10提前请求
      pageIndexList[i]++;
      Log.info("再次请求$_pageSize个数据");
      Future(() {
        return SqliteUtil.getAllAnimeBytagName(
            tags[i], animesInTag[i].length, _pageSize,
            animeSortCond: animeSortCond);
      }).then((value) {
        Log.info("请求结束");
        animesInTag[i].addAll(value);
        Log.info("添加并更新状态，animesInTag[$i].length=${animesInTag[i].length}");
        setState(() {});
      });
    }
  }

  void onPress(int animeIdx, Anime anime) {
    // 多选
    if (multiSelected) {
      if (mapSelected.containsKey(animeIdx)) {
        Log.info("[多选模式]移除animeIdx=$animeIdx");
        mapSelected.remove(animeIdx); // 选过，再选就会取消
        // 如果取消后一个都没选，就自动退出多选状态
        if (mapSelected.isEmpty) {
          multiSelected = false;
        }
      } else {
        Log.info("[多选模式]添加animeIdx=$animeIdx");
        mapSelected[animeIdx] = true;
      }
      setState(() {});
      return;
    } else {
      _enterPageAnimeDetail(anime);
    }
  }

  void onLongPress(int animeIdx) {
    // 非多选状态下才需要进入多选状态
    if (multiSelected == false) {
      multiSelected = true;
      mapSelected[animeIdx] = true;
      Log.info("[多选模式]添加animeIdx=$animeIdx");
      setState(() {}); // 添加操作按钮
    } else {
      // TODO 多选模式下，应提供范围选择
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
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          // actions: _getActions(),
        ));
  }

  void _dialogModifyTag(String defaultTagName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Widget> radioList = [];
        for (int i = 0; i < tags.length; ++i) {
          radioList.add(
            ListTile(
              title: Text(tags[i]),
              leading: tags[i] == defaultTagName
                  ? Icon(
                      Icons.radio_button_on_outlined,
                      color: ThemeUtil.getPrimaryColor(),
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                // 先找到原来清单对应的下标
                int oldTagindex = tags.indexOf(defaultTagName);
                int newTagindex = i;
                String newTagName = tags[newTagindex];
                // 删除元素后，后面的元素也会向前移动
                // 注意：map的key不是有序的，所以必须先转为有序的，否则先移动后面，在移动前面的元素就会出错(因为-j了)
                List<int> list = [];
                mapSelected.forEach((key, value) {
                  list.add(key);
                });
                mergeSort(list); // 排序
                // for (var item in list) {
                //   Log.info(item.toString());
                // }

                int j = 0;
                for (int m = 0; m < list.length; ++m) {
                  int pos = list[m] - j;

                  animesInTag[oldTagindex][pos].tagName = newTagName;
                  SqliteUtil.updateTagByAnimeId(
                      animesInTag[oldTagindex][pos].animeId, newTagName);
                  Log.info(
                      "修改${animesInTag[oldTagindex][pos].animeName}的清单为$newTagName");
                  Log.info("$pos: ${animesInTag[oldTagindex][pos]}");

                  animesInTag[newTagindex]
                      .insert(0, animesInTag[oldTagindex][pos]); // 添加到最上面
                  animesInTag[oldTagindex]
                      .removeAt(pos); // 第一次是正确位置key，第二次就需要-1了
                  j++;
                }
                // 同时修改清单数量
                int modifiedCnt = mapSelected.length;
                animeCntPerTag[oldTagindex] -= modifiedCnt;
                animeCntPerTag[newTagindex] += modifiedCnt;
                _quitMultiSelectState();
                Navigator.pop(context);
              },
            ),
          );
        }
        return AlertDialog(
          title: const Text('选择清单'),
          content: SingleChildScrollView(
            child: Column(
              children: radioList,
            ),
          ),
        );
      },
    );
  }

  void _quitMultiSelectState() {
    // 清空选择的动漫(注意在修改数量之后)，并消除多选状态
    multiSelected = false;
    mapSelected.clear();
    setState(() {});
  }

  List<Widget> _buildTagAndAnimeCnt() {
    List<Widget> list = [];
    for (int i = 0; i < tags.length; ++i) {
      list.add(Tab(
          child: Obx(
        () => _animeDisplayController.showAnimeCntAfterTag.value
            // 样式1：清单名(数量)
            // ? Text("${tags[i]} (${animeCntPerTag[i]})",
            //     textScaleFactor: ThemeUtil.smallScaleFactor)

            // 样式2：清单名紧跟缩小的数量
            ? Text.rich(TextSpan(children: [
                WidgetSpan(
                    child: Text(tags[i],
                        textScaleFactor: ThemeUtil.smallScaleFactor)),
                WidgetSpan(
                    child: Opacity(
                  opacity: 1.0, // 候选：0.8
                  child: Text(
                    animeCntPerTag[i].toString(),
                    textScaleFactor: ThemeUtil.tinyScaleFactor,
                  ),
                )),
              ]))
            : Text(tags[i], textScaleFactor: ThemeUtil.smallScaleFactor),
      )));
    }
    return list;
  }

  _buildBottomButton(i) {
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
                        // i就是当前清单的索引
                        if (mapSelected.length == animesInTag[i].length) {
                          // 全选了，点击则会取消全选
                          mapSelected.clear();
                        } else {
                          // 其他情况下，全选
                          for (int j = 0; j < animesInTag[i].length; ++j) {
                            mapSelected[j] = true;
                          }
                        }
                        setState(() {});
                      },
                      icon: const Icon(Icons.select_all_rounded),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        _dialogModifyTag(tags[i]);
                      },
                      icon: const Icon(Icons.checklist),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        _quitMultiSelectState();
                      },
                      icon: const Icon(Icons.exit_to_app_outlined),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  _getActionsOnMulti() {
    List<Widget> actions = [];
    return actions;
  }
}
