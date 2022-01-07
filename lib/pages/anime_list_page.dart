import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/scaffolds/anime_climb.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/scaffolds/search.dart';
import 'package:flutter_test_future/utils/clime_cover_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/tags.dart';
import 'package:oktoast/oktoast.dart';

class AnimeListPage extends StatefulWidget {
  const AnimeListPage({Key? key}) : super(key: key);

  @override
  _AnimeListPageState createState() => _AnimeListPageState();
}

class _AnimeListPageState extends State<AnimeListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String addDefaultTag = tags[0];
  List<int> animeCntPerTag = []; // 各个标签下的动漫数量
  List<List<Anime>> animesInTag = []; // 各个标签下的动漫列表

  // 数据加载
  bool _loadOk = false;
  List<int> pageIndex = List.generate(tags.length, (index) => 1); // 初始页都为1
  final int _pageSize = 50;
  // int _pageIndex = 1;
  // final int _pageSize = 50;

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
        addDefaultTag = tags[_tabController.index]; // 切换顶层tab后，默认添加动漫标签为当前tab标签
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
        debugPrint("animesInTag[$i].length=${animesInTag[i].length}");
      }
      debugPrint("animesInTag[0].length=${animesInTag[0].length}");
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
      duration: const Duration(milliseconds: 100),
      child: !_loadOk
          ? _waitDataScaffold()
          : Scaffold(
              // key: UniqueKey(), // 加载这里会导致多选每次点击都会有动画，所以值需要在_waitDataScaffold中加就可以了
              appBar: AppBar(
                title: const Text(
                  "动漫",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: _getActions(),
                bottom: PreferredSize(
                  // 默认情况下，要将标签栏与相同的标题栏高度对齐，可以使用常量kToolbarHeight
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TabBar(
                      padding: const EdgeInsets.all(2), // 居中，而不是靠左下
                      labelPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      isScrollable: true, // 标签可以滑动，避免拥挤
                      unselectedLabelColor: Colors.black54,
                      labelColor: Colors.blue, // 标签字体颜色
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      indicatorColor: Colors.transparent, // 隐藏
                      // indicatorColor: Colors.blue, // 指示器颜色
                      indicatorSize: TabBarIndicatorSize.label, // 指示器长短和标签一样
                      indicatorWeight: 3, // 指示器高度
                      tabs: _showTagAndAnimeCntPlus(),
                      // tabs: loadOk ? _showTagAndAnimeCntPlus() : _waitDataPage(),
                      controller: _tabController,
                    ),
                  ),
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: _getAnimesPlus(),
              ),
              floatingActionButton: multiSelected
                  ? null // 多选时隐藏添加按钮
                  : FloatingActionButton(
                      heroTag: null,
                      onPressed: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                                builder: (context) => const AnimeClimb()))
                            .then((value) {
                          _loadData(); // 重新加载数据，显示新添加的动漫
                        });
                        // _dialogAddAnime();
                      },
                      child: const Icon(Icons.add),
                    ),
            ),
    );
  }

  List<Widget> _getActions() {
    List<Widget> actions = [];
    actions.add(
      IconButton(
        onPressed: () async {
          List<Anime> animes;
          showToast("开始更新");
          animes = await SqliteUtil.getAllAnimes();
          for (var anime in animes) {
            // 已有封面直接跳过
            if (anime.animeCoverUrl.isNotEmpty) {
              if (anime.animeCoverUrl.startsWith("//")) {
                anime.animeCoverUrl = "https:${anime.animeCoverUrl}";
                // 更新链接(前面加上https:)
                SqliteUtil.updateAnimeCoverbyAnimeId(
                    anime.animeId, anime.animeCoverUrl);
              }
              debugPrint("${anime.animeName}已有封面：'${anime.animeCoverUrl}'，跳过");
              continue;
            }
            String coverUrl =
                await ClimeCoverUtil.climeCoverUrl(anime.animeName);
            debugPrint("${anime.animeName}封面：$coverUrl");
            // 返回的链接不为空字符串，更新封面
            if (coverUrl.isNotEmpty) {
              SqliteUtil.updateAnimeCoverbyAnimeId(anime.animeId, coverUrl);
              // _loadData(); // 不太好，每次刷新整个页面
              for (var animes in animesInTag) {
                int findIndex = animes
                    .indexWhere((element) => element.animeId == anime.animeId);
                if (findIndex != -1) {
                  // 找到后更新，然后直接退出循环
                  setState(() {
                    animes[findIndex].animeCoverUrl = coverUrl;
                  });
                  break;
                }
                // 尽管由于分页有些动漫还不在请求的数据中，如果找不到就不用改就行了，并不影响
              }
            }
          }
          showToast("更新完成");
          // _loadData(); // 更新完成后重新获取
        },
        icon: const Icon(Icons.refresh),
        tooltip: "刷新封面",
        color: Colors.black,
      ),
    );
    actions.add(
      IconButton(
        onPressed: () async {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const Search(),
            ),
          );
        },
        icon: const Icon(Icons.search_outlined),
        tooltip: "搜索动漫",
        color: Colors.black,
      ),
    );
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
            _showBottomButton(i),
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
              // padding: const EdgeInsets.fromLTRB(5, 5, 5, 5), // 设置按钮填充
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
                                      const EdgeInsets.fromLTRB(2, 2, 2, 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    color: Colors.blue,
                                  ),
                                  child: Text(
                                    "${anime.checkedEpisodeCnt}/${anime.animeEpisodeCnt}",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  ),
                                )),
                      ],
                    ),
                    SPUtil.getBool("hideGridAnimeName")
                        ? Container()
                        : Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    anime.animeName,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: Platform.isAndroid
                                        ? const TextStyle(fontSize: 13)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
                Container(
                  color: mapSelected.containsKey(index)
                      ? multiSelectedColor
                      : null,
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
            style: const TextStyle(
              fontSize: 15,
              // fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis, // 避免名字过长，导致显示多行
          ),
          leading: AnimeListCover(anime),
          trailing: Text(
            "${anime.checkedEpisodeCnt}/${anime.animeEpisodeCnt}",
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black,
              // fontWeight: FontWeight.w400,
            ),
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
    }
    _enterPageAnimeDetail(i, index, anime);
  }

  void onLongPress(index) {
    // 非多选状态下才需要进入多选状态
    if (multiSelected == false) {
      multiSelected = true;
      mapSelected[index] = true;
      setState(() {}); // 添加操作按钮
    }
  }

  void _enterPageAnimeDetail(i, index, anime) {
    Navigator.of(context)
        .push(
      // 1.默认
      MaterialPageRoute(
        builder: (context) => AnimeDetailPlus(anime.animeId),
      ),
      // 2.渐进
      // PageRouteBuilder(
      //   transitionDuration: const Duration(milliseconds: 100),
      //   reverseTransitionDuration:
      //       const Duration(milliseconds: 100),
      //   pageBuilder: (BuildContext context,
      //       Animation<double> animation,
      //       Animation secondaryAnimation) {
      //     return FadeTransition(
      //       //使用渐隐渐入过渡,
      //       opacity: animation,
      //       child: AnimeDetailPlus(anime.animeId),
      //     );
      //   },
      // ),
      // 3.bug：返回无渐进
      // FadeRoute(
      //   builder: (context) {
      //     return AnimeDetailPlus(anime.animeId);
      //   },
      // ),
    )
        .then((value) {
      debugPrint(value.toString());
      // anime = value; // 无效是因为anime是局部变量，和页面状态无关，所以setState没有作用
      Anime newAnime = value;
      // 如果更换了标签，则还要移动到相应的标签
      if (anime.tagName != newAnime.tagName) {
        // debugPrint("${anime.tagName}, ${newAnime.tagName}");
        // debugPrint("old: ${anime.toString()}");
        int newTagIndex = tags.indexOf(newAnime.tagName);
        animesInTag[i].removeAt(index); // 从该标签中删除旧动漫
        animesInTag[newTagIndex].insert(0, newAnime); // 向新标签添加新动漫
        // 还要改变标签的数量
        animeCntPerTag[i]--;
        animeCntPerTag[newTagIndex]++;
        // debugPrint("移动了标签");
      } else {
        animesInTag[i][index] = newAnime;
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
              color: Colors.black,
              fontWeight: FontWeight.bold,
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

  List<Widget> _showTagAndAnimeCntPlus() {
    List<Widget> list = [];
    for (int i = 0; i < tags.length; ++i) {
      list.add(Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          Text(
            "${tags[i]} (${animeCntPerTag[i]})",
            // style: const TextStyle(fontFamily: "hm"),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ));
    }
    return list;
  }

  _showBottomButton(i) {
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
                      color: Colors.black,
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        _dialogModifyTag(tags[i]);
                      },
                      icon: const Icon(Icons.new_label_outlined),
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
}
