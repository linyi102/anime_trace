import 'dart:ui';

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

  bool _loadOk = false;
  int _pageIndex = 1;
  final int _pageSize = 50;

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
          child: ListView.builder(
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
              return ListTile(
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
                      animesInTag[newTagIndex].insert(0, newAnime); // 向新标签添加新动漫
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
                onLongPress: () {},
              );
            },
          ),
        ),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return !_loadOk
        ? _waitDataScaffold()
        : Scaffold(
            appBar: AppBar(
              toolbarHeight: 0, // 太小容易导致底部不够，从而溢出
              backgroundColor: Colors.white,
              shadowColor: Colors.transparent,
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
              color: const Color.fromRGBO(250, 250, 250, 1),
              child: TabBarView(
                controller: _tabController,
                // children: _getAnimeList(),
                children: _getAnimesPlus(),
                // children: loadOk ? _getAnimesPlus() : _waitDataPage(),
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
        backgroundColor: Colors.white,
        shadowColor: Colors.transparent,
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
      body: const Center(
          // child: CircularProgressIndicator(),
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

class AnimeItem extends StatefulWidget {
  Anime anime;
  AnimeItem(
    this.anime, {
    Key? key,
  }) : super(key: key);

  @override
  State<AnimeItem> createState() => _AnimeItemState();
}

class _AnimeItemState extends State<AnimeItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        widget.anime.animeName,
        style: const TextStyle(
          fontSize: 15,
          // fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis, // 避免名字过长，导致显示多行
      ),
      trailing: Text(
        "${widget.anime.checkedEpisodeCnt}/${widget.anime.animeEpisodeCnt}",
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black,
          // fontWeight: FontWeight.w400,
        ),
      ),
      onTap: () {
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (context) => AnimeDetailPlus(widget.anime.animeId),
          ),
        )
            .then((value) {
          debugPrint(value.toString());
          setState(() {
            widget.anime = value;
          });
        });
      },
      onLongPress: () {},
    );
  }
}
