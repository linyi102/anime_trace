import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/tags.dart';

class AnimeListPage extends StatefulWidget {
  const AnimeListPage({Key? key}) : super(key: key);

  @override
  _AnimeListPageState createState() => _AnimeListPageState();
}

class _AnimeListPageState extends State<AnimeListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String addDefaultTag = tags[0];
  List<int> _animeCntPerTag = [];
  List<List<Anime>> animesInTag = [];
  Map<int, bool> mapSelected = {};

  bool _loadOk = false;
  int _pageIndex = 1;
  final int _pageSize = 50;

  bool multiSelected = false;

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
      }
    });
  }

  _loadData() async {
    debugPrint("开始加载数据");
    Future(() async {
      _animeCntPerTag = await SqliteUtil.getAnimeCntPerTag();
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

  List<Widget> _getAnimesPlus() {
    List<Widget> list = [];
    for (int i = 0; i < tags.length; ++i) {
      list.add(
        Scrollbar(
          thickness: 5,
          radius: const Radius.circular(10),
          child: Stack(children: [
            ListView.builder(
              itemCount: animesInTag[i].length,
              // itemCount: _animeCntPerTag[i], // 假装先有这么多，容易导致越界(虽然没啥影响)，但还是不用了吧
              itemBuilder: (BuildContext context, int index) {
                // debugPrint("index=$index");
                // 直接使用index会导致重复请求
                // 增加pageIndex变量，每当index增加到pageSize*pageIndex，就开始请求一页数据
                // 例：最开始，pageIndex=1，有pageSize=50个数据，当index到达50(50*1)时，会再次请求50个数据
                // 当到达100(50*2)时，会再次请求50个数据
                if (index + 10 == _pageSize * (_pageIndex)) {
                  // +10提前请求
                  _pageIndex++;
                  debugPrint("再次请求$_pageSize个数据");
                  Future(() {
                    return SqliteUtil.getAllAnimeBytagName(
                        tags[i], animesInTag[i].length, _pageSize);
                  }).then((value) {
                    debugPrint("请求结束");
                    animesInTag[i].addAll(value);
                    debugPrint("添加并更新状态");
                    setState(() {});
                  });
                }
                // debugPrint("$index");
                // return AnimeItem(animesInTag[i][index]);
                Anime anime = animesInTag[i][index];
                return Container(
                  color: mapSelected.containsKey(index)
                      ? const Color.fromRGBO(0, 118, 243, 0.1)
                      : Colors.white,
                  child: ListTile(
                    // 不管用
                    // tileColor: isSelected.containsKey(index)
                    //     ? Colors.grey
                    //     : Colors.white,
                    visualDensity: const VisualDensity(vertical: -1),
                    title: Text(
                      anime.animeName,
                      style: const TextStyle(
                        fontSize: 15,
                        // fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis, // 避免名字过长，导致显示多行
                    ),
                    trailing: Text(
                      "${anime.checkedEpisodeCnt}/${anime.animeEpisodeCnt}",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        // fontWeight: FontWeight.w400,
                      ),
                    ),
                    onTap: () {
                      // 多选
                      if (multiSelected) {
                        if (mapSelected.containsKey(index)) {
                          mapSelected.remove(index); // 选过，再选就会取消s
                        } else {
                          mapSelected[index] = true;
                        }
                        setState(() {});
                        return;
                      }
                      // 非多选
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                        builder: (context) => AnimeDetailPlus(anime.animeId),
                      ))
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
                          animesInTag[newTagIndex]
                              .insert(0, newAnime); // 向新标签添加新动漫
                          // 还要改变标签的数量
                          _animeCntPerTag[i]--;
                          _animeCntPerTag[newTagIndex]++;
                          // debugPrint("移动了标签");
                        } else {
                          animesInTag[i][index] = newAnime;
                        }
                        setState(() {});
                      });
                    },
                    onLongPress: () {
                      multiSelected = true;
                      mapSelected[index] = true;
                      setState(() {}); // 添加操作按钮
                    },
                  ),
                );
              },
            ),
            // 一定要叠放在ListView上面，否则点击按钮没有反应
            !multiSelected
                ? Container()
                : Container(
                    alignment: Alignment.bottomCenter,
                    child: Card(
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(15))), // 圆角
                      clipBehavior: Clip.antiAlias, // 设置抗锯齿，实现圆角背景
                      color: const Color.fromRGBO(0, 118, 243, 0.1),
                      margin: const EdgeInsets.fromLTRB(50, 20, 50, 20),
                      child: Row(
                        // mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: IconButton(
                              onPressed: () {
                                // i就是当前标签的索引
                                if (mapSelected.length ==
                                    animesInTag[i].length) {
                                  // 全选了，点击则会取消全选
                                  mapSelected.clear();
                                } else {
                                  // 其他情况下，全选
                                  for (int j = 0;
                                      j < animesInTag[i].length;
                                      ++j) {
                                    mapSelected[j] = true;
                                  }
                                }

                                setState(() {});
                              },
                              icon: const Icon(Icons.select_all_rounded),
                              color: Colors.blueAccent,
                            ),
                          ),
                          Expanded(
                            child: IconButton(
                              onPressed: () {
                                _dialogModifyTag(tags[i]);
                              },
                              icon: const Icon(Icons.label_outline_rounded),
                              color: Colors.blueAccent,
                            ),
                          ),
                          // Expanded(
                          //   child: IconButton(
                          //     onPressed: () {},
                          //     icon: const Icon(Icons.delete_outline_rounded),
                          //     color: Colors.blueAccent,
                          //   ),
                          // ),
                          Expanded(
                            child: IconButton(
                              onPressed: () {
                                multiSelected = false;
                                // 记得清空选择的动漫
                                mapSelected.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.exit_to_app_outlined),
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ]),
        ),
      );
    }
    // list.clear();
    // for (int i = 0; i < tags.length; ++i) {
    //   list.add(ListView(
    //     children: [
    //       ListTile(
    //         title: const Text("测试"),
    //         onTap: () {},
    //         onLongPress: () {},
    //       )
    //     ],
    //   ));
    // }
    return list;
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: ListView(
  //       children: [
  //         ListTile(
  //           title: const Text("测试"),
  //           onTap: () {},
  //         )
  //       ],
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return !_loadOk
        ? _waitDataScaffold()
        : Scaffold(
            appBar: AppBar(
              toolbarHeight: 0, // 太小容易导致底部不够，从而溢出
              bottom: TabBar(
                isScrollable: true, // 标签可以滑动，避免拥挤
                unselectedLabelColor: Colors.black54,
                labelColor: Colors.blue, // 标签字体颜色
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                indicatorColor: Colors.blue, // 指示器颜色
                indicatorSize: TabBarIndicatorSize.label, // 指示器长短和标签一样
                indicatorWeight: 3, // 指示器高度
                tabs: _showTagAndAnimeCntPlus(),
                // tabs: loadOk ? _showTagAndAnimeCntPlus() : _waitDataPage(),
                controller: _tabController,
              ),
            ),
            body: Container(
              // color: const Color.fromRGBO(250, 250, 250, 1),
              color: Colors.white,
              child: TabBarView(
                controller: _tabController,
                children: _getAnimesPlus(),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                _dialogAddAnime();
              },
              child: const Icon(Icons.add),
            ),
          );
  }

  Scaffold _waitDataScaffold() {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0, // 太小容易导致底部不够，从而溢出
        // bottom: TabBar(
        //   tabs: const [],
        //   indicatorWeight: 3,
        //   controller: TabController(
        //     initialIndex: 0, // 设置初始index
        //     length: 1,
        //     vsync: this,
        //   ),
        // ),
      ),
      body: Container(
        color: Colors.white,
      ),
    );
  }

  void _dialogAddAnime() {
    var inputNameController = TextEditingController();
    var inputEndEpisodeController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String _labelTextInEpisodeField = "动漫集数：12";
        return StatefulBuilder(builder: (context, setTagStateOnAddAnime) {
          return AlertDialog(
            title: const Text('添加动漫'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    controller: inputNameController,
                    decoration: const InputDecoration(
                      labelText: "动漫名称",
                      border: InputBorder.none,
                    ),
                  ),
                  TextField(
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    controller: inputEndEpisodeController,
                    decoration: InputDecoration(
                      labelText: _labelTextInEpisodeField,
                      border: InputBorder.none,
                    ),
                    onTap: () {
                      setTagStateOnAddAnime(() {
                        _labelTextInEpisodeField = "动漫集数";
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  _dialogSelectTag(setTagStateOnAddAnime);
                },
                icon: const Icon(
                  Icons.new_label,
                  size: 26,
                  color: Colors.blue,
                ),
                label: Text(
                  addDefaultTag,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  String name = inputNameController.text;
                  if (name.isEmpty) return;

                  String endEpisodeStr = inputEndEpisodeController.text;
                  int endEpisode = 12;
                  if (endEpisodeStr.isNotEmpty) {
                    endEpisode = int.parse(inputEndEpisodeController.text);
                  }
                  Anime newAnime = Anime(
                      animeName: name,
                      animeEpisodeCnt: endEpisode,
                      tagName: addDefaultTag);
                  SqliteUtil.insertAnime(newAnime);
                  int tagIndex = tags.indexOf(addDefaultTag);
                  // 必须要得到在anime表中新插入的动漫的id，然后再添加到animesInTag[tagIndex]中，否则添加完后就无法根据id进入详细页面
                  newAnime.animeId = await SqliteUtil.getAnimeLastId();
                  _animeCntPerTag[tagIndex]++; // 增加标签的显示数量
                  animesInTag[tagIndex].insert(0, newAnime);
                  setState(() {});
                  // 改变状态
                  // Future.delayed(const Duration(milliseconds: 10), () {
                  //   setState(() {});
                  // });
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.send),
                label: const Text(""),
              ),
            ],
          );
        });
      },
    );
  }

  // 传入动漫对话框的状态，选择好标签后，就会更新该状态
  void _dialogSelectTag(setTagStateOnAddAnime) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Widget> radioList = [];
        for (int i = 0; i < tags.length; ++i) {
          radioList.add(
            ListTile(
              title: Text(tags[i]),
              leading: tags[i] == addDefaultTag
                  ? const Icon(
                      Icons.radio_button_on_outlined,
                      color: Colors.blue,
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                addDefaultTag = tags[i];
                setTagStateOnAddAnime(() {});
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
                  SqliteUtil.updateTagNameByAnimeId(
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
                _animeCntPerTag[oldTagindex] -= modifiedCnt;
                _animeCntPerTag[newTagindex] += modifiedCnt;
                // 记得清空选择的动漫(注意在修改数量之后)
                mapSelected.clear();
                // 并消除多选状态
                multiSelected = false;
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

  List<Widget> _showTagAndAnimeCntPlus() {
    List<Widget> list = [];
    for (int i = 0; i < tags.length; ++i) {
      list.add(Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          Text(
            "${tags[i]} (${_animeCntPerTag[i]})",
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
}
