import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/scaffolds/search_db_anime.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/theme_util.dart';

class AnimeListPage extends StatefulWidget {
  const AnimeListPage({Key? key}) : super(key: key);

  @override
  _AnimeListPageState createState() => _AnimeListPageState();
}

class _AnimeListPageState extends State<AnimeListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 数据加载
  bool _loadOk = false;
  bool _transitOk = false;
  List<int> pageIndex = List.generate(tags.length, (index) => 1); // 初始页都为1
  final int _pageSize = 50;

  // 多选
  Map<int, bool> mapSelected = {};
  bool multiSelected = false;
  Color multiSelectedColor = Colors.blueAccent.withOpacity(0.25);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < tags.length; ++i) {
      animesInTag.add([]); // 先添加元素List，然后才能用下标访问
    }
    Future.delayed(const Duration(milliseconds: 1)).then((value) {
      setState(() {
        _transitOk = true;
      });
    });

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
    debugPrint("开始加载数据");
    Future(() async {
      animeCntPerTag = await SqliteUtil.getAnimeCntPerTag();
      for (int i = 0; i < tags.length; ++i) {
        animesInTag[i] =
            await SqliteUtil.getAllAnimeBytagName(tags[i], 0, _pageSize);
        // debugPrint("animesInTag[$i].length=${animesInTag[i].length}");
      }
    }).then((value) {
      debugPrint("数据加载完毕");
      _loadOk = true; // 放这里啊，之前干嘛放外面...
      setState(() {}); // 数据加载完毕后，再刷新页面。注意下面数据未加载完毕时，由于loadOk为false，显示的是其他页面
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      // 仅在第一次加载(animeCntPerTag为空)时才显示空白，之后切换到该页面时先显示旧数据
      // 然后再通过_loadData覆盖掉旧数据
      // 美化：显示旧数据时也由空白页面过渡
      child: !_loadOk && animeCntPerTag.isEmpty
          ? _waitDataScaffold()
          : !_transitOk
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
                    actions:
                        multiSelected ? _getActionsOnMulti() : _getActions(),
                    bottom: PreferredSize(
                      // 默认情况下，要将标签栏与相同的标题栏高度对齐，可以使用常量kToolbarHeight
                      preferredSize: const Size.fromHeight(kToolbarHeight),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TabBar(
                          tabs: _buildTagAndAnimeCnt(),
                          // tabs: loadOk ? _showTagAndAnimeCntPlus() : _waitDataPage(),
                          controller: _tabController,
                          padding: const EdgeInsets.all(2), // 居中，而不是靠左下
                          isScrollable: true, // 标签可以滑动，避免拥挤
                          labelPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                          // indicatorColor: Colors.transparent, // 隐藏
                          // indicatorSize:
                          //     TabBarIndicatorSize.label, // 指示器长短和标签一样
                          indicator: BoxDecoration(
                              // borderRadius: BorderRadius.only(
                              //     topLeft: Radius.circular(2),
                              //     topRight: Radius.circular(2)),
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.blue),
                          indicatorPadding: const EdgeInsets.only(
                              left: 20, right: 20, top: 39),
                          indicatorWeight: 3, // 指示器高度
                        ),
                      ),
                    ),
                  ),
                  body: TabBarView(
                    controller: _tabController,
                    children: _getAnimesPlus(),
                  ),
                  floatingActionButton: FloatingActionButton(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        Navigator.of(context).push(
                          // MaterialPageRoute(
                          //   builder: (context) => const Search(),
                          // ),
                          FadeRoute(
                            builder: (context) {
                              return const SearchDbAnime();
                            },
                          ),
                        ).then((value) {
                          debugPrint("更新在搜索页面里进行的修改");
                          _loadData();
                        });
                      });
                    },
                    child: const Icon(Icons.search_rounded),
                  ),
                ),
    );
  }

  List<Widget> _getActions() {
    List<Widget> actions = [];
    // actions.add(
    //   IconButton(
    //     onPressed: () async {
    //       Navigator.of(context).push(
    //         // MaterialPageRoute(
    //         //   builder: (context) => const Search(),
    //         // ),
    //         FadeRoute(
    //           builder: (context) {
    //             return const SearchDbAnime();
    //           },
    //         ),
    //       ).then((value) {
    //         debugPrint("更新在搜索页面里进行的修改");
    //         _loadData();
    //       });
    //     },
    //     icon: const Icon(Icons.search_outlined),
    //     tooltip: "搜索动漫",
    //   ),
    // );
    return actions;
  }

  List<Widget> _getAnimesPlus() {
    List<Widget> list = [];
    for (int i = 0; i < tags.length; ++i) {
      list.add(
        Scrollbar(
          child: Stack(children: [
            SPUtil.getBool("display_list")
                ? _getAnimeListView(i)
                : _getAnimeGridView(i),
            // 一定要叠放在ListView上面，否则点击按钮没有反应
            _buildBottomButton(i),
          ]),
        ),
      );
    }
    return list;
  }

  GridView _getAnimeGridView(int i) {
    return GridView.builder(
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 5), // 整体的填充
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              SPUtil.getInt("gridColumnCnt", defaultValue: 3), // 横轴数量
          crossAxisSpacing: 5, // 横轴距离
          mainAxisSpacing: 3, // 竖轴距离
          childAspectRatio: SPUtil.getBool("hideGridAnimeName")
              ? 31 / 48
              : 31 / 56, // 每个网格的比例
        ),
        itemCount: animesInTag[i].length,
        itemBuilder: (BuildContext context, int index) {
          _loadExtraData(i, index);
          Anime anime = animesInTag[i][index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: MaterialButton(
              onPressed: () {
                onpress(i, index, anime);
              },
              onLongPress: () {
                onLongPress(index);
              },
              padding: const EdgeInsets.all(0),
              child: Stack(children: [
                Column(
                  children: [
                    Stack(
                      children: [
                        AnimeGridCover(anime),
                        SPUtil.getBool("hideGridAnimeProgress")
                            ? Container()
                            : Positioned(
                                left: 5,
                                top: 5,
                                child: Container(
                                  // height: 20,
                                  padding:
                                      const EdgeInsets.fromLTRB(3, 2, 3, 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    color: Colors.blue,
                                  ),
                                  child: Text(
                                    "${anime.checkedEpisodeCnt}/${anime.animeEpisodeCnt}",
                                    textScaleFactor: 0.8,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                )),
                        SPUtil.getBool("hideReviewNumber")
                            ? Container()
                            : anime.reviewNumber == 1
                                ? Container()
                                : Positioned(
                                    right: 5,
                                    top: 5,
                                    child: Container(
                                      padding:
                                          const EdgeInsets.fromLTRB(2, 2, 2, 2),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          color: Colors.orange),
                                      child: Text(" ${anime.reviewNumber} ",
                                          textScaleFactor: 0.8,
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    )),
                      ],
                    ),
                    SPUtil.getBool("hideGridAnimeName")
                        ? Container()
                        : Padding(
                            padding: const EdgeInsets.only(
                                top: 2, left: 3, right: 3),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(anime.animeName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textScaleFactor: 0.9,
                                      style: TextStyle(
                                          color: ThemeUtil.getFontColor())),
                                )
                              ],
                            ))
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    // border: mapSelected.containsKey(index)
                    //     ? Border.all(width: 3, color: Colors.blue)
                    //     : null,
                    borderRadius: BorderRadius.circular(5),
                    color: mapSelected.containsKey(index)
                        ? multiSelectedColor
                        : null,
                  ),
                ),
              ]),
            ),
          );
        });
  }

  ListView _getAnimeListView(int i) {
    return ListView.builder(
      itemCount: animesInTag[i].length,
      // itemCount: _animeCntPerTag[i], // 假装先有这么多，容易导致越界(虽然没啥影响)，但还是不用了吧
      itemBuilder: (BuildContext context, int index) {
        _loadExtraData(i, index);

        // debugPrint("$index");
        // return AnimeItem(animesInTag[i][index]);
        Anime anime = animesInTag[i][index];
        return ListTile(
          selectedTileColor: multiSelectedColor,
          selected: mapSelected.containsKey(index),
          selectedColor: Colors.black,
          // visualDensity: const VisualDensity(vertical: -1),
          title: Text(
            anime.animeName,
            textScaleFactor: 0.9,
            overflow: TextOverflow.ellipsis, // 避免名字过长，导致显示多行
          ),
          leading: AnimeListCover(
            anime,
            showReviewNumber: !SPUtil.getBool("hideReviewNumber"),
            reviewNumber: anime.reviewNumber,
          ),
          trailing: Text(
            "${anime.checkedEpisodeCnt}/${anime.animeEpisodeCnt}",
            textScaleFactor: 0.9,
          ),
          onTap: () {
            onpress(i, index, anime);
          },
          onLongPress: () {
            onLongPress(index);
          },
        );
      },
    );
  }

  void _loadExtraData(i, index) {
    // debugPrint("index=$index");
    // 直接使用index会导致重复请求
    // 增加pageIndex变量，每当index增加到pageSize*pageIndex，就开始请求一页数据
    // 例：最开始，pageIndex=1，有pageSize=50个数据，当index到达50(50*1)时，会再次请求50个数据
    // 当到达100(50*2)时，会再次请求50个数据
    if (index + 10 == _pageSize * (pageIndex[i])) {
      // +10提前请求
      pageIndex[i]++;
      debugPrint("再次请求$_pageSize个数据");
      Future(() {
        return SqliteUtil.getAllAnimeBytagName(
            tags[i], animesInTag[i].length, _pageSize);
      }).then((value) {
        debugPrint("请求结束");
        animesInTag[i].addAll(value);
        debugPrint("添加并更新状态，animesInTag[$i].length=${animesInTag[i].length}");
        setState(() {});
      });
    }
  }

  void onpress(i, index, anime) {
    // 多选
    if (multiSelected) {
      if (mapSelected.containsKey(index)) {
        mapSelected.remove(index); // 选过，再选就会取消
        // 如果取消后一个都没选，就自动退出多选状态
        if (mapSelected.isEmpty) {
          multiSelected = false;
        }
      } else {
        mapSelected[index] = true;
      }
      setState(() {});
      return;
    } else {
      _enterPageAnimeDetail(i, index, anime);
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

  void _enterPageAnimeDetail(i, index, Anime anime) {
    Navigator.of(context)
        .push(
      FadeRoute(
        transitionDuration: const Duration(milliseconds: 0),
        builder: (context) {
          return AnimeDetailPlus(anime.animeId);
        },
      ),
    )
        .then((value) async {
      // 根据传回的动漫id获取最新的更新进度以及标签
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
          // 标签改变，则移动到新的标签组
          Anime oldAnime = animesInTag[tagIndex][findIndex];
          if (oldAnime.tagName != newAnime.tagName) {
            animesInTag[tagIndex].removeAt(findIndex);
            int newTagIndex =
                tags.indexWhere((element) => element == newAnime.tagName);
            animesInTag[newTagIndex].insert(0, newAnime); // 插到最前面
            // 还要改变标签的数量
            animeCntPerTag[tagIndex]--;
            animeCntPerTag[newTagIndex]++;
          } else {
            // 标签没变，简单改下进度
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
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: _getActions(),
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
                  ? const Icon(
                      Icons.radio_button_on_outlined,
                      color: Colors.blue,
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                // 先找到原来标签对应的下标
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
                //   debugPrint(item.toString());
                // }

                int j = 0;
                for (int m = 0; m < list.length; ++m) {
                  int pos = list[m] - j;

                  animesInTag[oldTagindex][pos].tagName = newTagName;
                  SqliteUtil.updateTagByAnimeId(
                      animesInTag[oldTagindex][pos].animeId, newTagName);
                  debugPrint(
                      "修改${animesInTag[oldTagindex][pos].animeName}的标签为$newTagName");
                  debugPrint("$pos: ${animesInTag[oldTagindex][pos]}");

                  animesInTag[newTagindex]
                      .insert(0, animesInTag[oldTagindex][pos]); // 添加到最上面
                  animesInTag[oldTagindex]
                      .removeAt(pos); // 第一次是正确位置key，第二次就需要-1了
                  j++;
                }
                // 同时修改标签数量
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

  void _quitMultiSelectState() {
    // 清空选择的动漫(注意在修改数量之后)，并消除多选状态
    multiSelected = false;
    mapSelected.clear();
    setState(() {});
  }

  List<Widget> _buildTagAndAnimeCnt() {
    List<Widget> list = [];
    for (int i = 0; i < tags.length; ++i) {
      list.add(Column(
        children: [
          const SizedBox(height: 10),
          Text("${tags[i]} (${animeCntPerTag[i]})"),
          const SizedBox(height: 10)
        ],
      ));
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
                  borderRadius: BorderRadius.all(Radius.circular(50))), // 圆角
              clipBehavior: Clip.antiAlias, // 设置抗锯齿，实现圆角背景
              margin: const EdgeInsets.fromLTRB(80, 20, 80, 20),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        // i就是当前标签的索引
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
                      icon: const Icon(Icons.new_label_outlined),
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
