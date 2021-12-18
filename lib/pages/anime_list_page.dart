import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/scaffolds/anime_sql_detail.dart';
import 'package:flutter_test_future/sql/anime_sql.dart';
import 'package:flutter_test_future/sql/sqlite_helper.dart';
import 'package:flutter_test_future/utils/tags.dart';

int lastTopTabIndex = 0;

class AnimeListPage extends StatefulWidget {
  const AnimeListPage({Key? key}) : super(key: key);

  @override
  _AnimeListPageState createState() => _AnimeListPageState();
}

class _AnimeListPageState extends State<AnimeListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String addDefaultTag = tags[0];
  SqliteHelper sqliteHelper = SqliteHelper.getInstance();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: lastTopTabIndex, // 设置初始index
      length: 5,
      vsync: this,
    );
    // 添加监听器，记录最后一次的topTab的index
    _tabController.addListener(() {
      if (_tabController.index == _tabController.animation!.value) {
        lastTopTabIndex = _tabController.index;
      }
    });
    debugPrint("init");
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Widget> _getAnimeList() {
    List<Widget> list = [];
    for (int i = 0; i < tags.length; ++i) {
      list.add(
        Scrollbar(
          thickness: 5,
          radius: const Radius.circular(10),
          child: FutureBuilder(
            future: sqliteHelper.getAllAnimeBytag(tags[i]),
            // future结束后会通知builder重新渲染画面，因此stateless也可以
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.hasError) {
                debugPrint(snapshot.error.toString());
                // return const Text("");
                return Text(snapshot.error.toString());
                // return const Icon(
                //   Icons.error,
                //   size: 80,
                // );
              }
              if (snapshot.hasData) {
                List<AnimeSql> list = snapshot.data as List<AnimeSql>;
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (BuildContext context, int index) {
                    // debugPrint("index=${index.toString()}");
                    AnimeSql e = list[index];
                    return ListTile(
                      title: Text(
                        e.animeName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontFamily: 'NotoSans',
                          // fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis, // 避免名字过长，导致显示多行
                      ),
                      trailing: Text(
                        "${e.checkedEpisodeCnt}/${e.animeEpisodeCnt}",
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          // fontWeight: FontWeight.w400,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AnimeDetailPlus(e.animeId),
                          ),
                        );
                      },
                      onLongPress: () {},
                    );
                  },
                );
              }
              // 等待数据时显示加载画面
              // return const CircularProgressIndicator();
              return const Text("");
            },
          ),
        ),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 8, // 太小容易导致底部不够，从而溢出
        backgroundColor: Colors.white,
        shadowColor: Colors.transparent,
        bottom: TabBar(
          unselectedLabelColor: Colors.black54,
          labelColor: Colors.blue, // 标签字体颜色
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          indicatorColor: Colors.blue, // 指示器颜色
          indicatorSize: TabBarIndicatorSize.label, // 指示器长短和标签一样
          indicatorWeight: 3, // 指示器高度
          tabs: _showTagAndAnimeCnt(),
          controller: _tabController,
        ),
      ),
      body: Container(
        color: Colors.white, // 使用函数设置颜色没有效果，很奇怪
        child: TabBarView(
          controller: _tabController,
          children: _getAnimeList(),
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
            content: AspectRatio(
              aspectRatio: 2 / 1,
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
                onPressed: () {
                  String name = inputNameController.text;
                  if (name.isEmpty) {
                    return;
                  }
                  String endEpisodeStr = inputEndEpisodeController.text;
                  int endEpisode = 12;
                  if (endEpisodeStr.isNotEmpty) {
                    endEpisode = int.parse(inputEndEpisodeController.text);
                  }
                  // 改变状态
                  sqliteHelper.insertAnime(AnimeSql(
                      animeName: name,
                      animeEpisodeCnt: endEpisode,
                      tagName: addDefaultTag));
                  Future.delayed(const Duration(milliseconds: 10), () {
                    setState(() {
                      debugPrint("👉setState");
                    });
                  });
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
    int groupValue = tags.indexOf(addDefaultTag); // 默认选择
    // String selectTag = tags[0];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, tagState) {
          List<Widget> radioList = [];
          for (int i = 0; i < tags.length; ++i) {
            radioList.add(
              Row(
                children: [
                  Radio(
                    value: i,
                    groupValue: groupValue,
                    onChanged: (v) {
                      tagState(() {
                        groupValue = int.parse(v.toString());
                      });
                      setTagStateOnAddAnime(() {
                        addDefaultTag = tags[i];
                      });
                      Navigator.pop(context);
                    },
                  ),
                  Text(tags[i]),
                ],
              ),
            );
          }

          return AlertDialog(
            title: const Text('选择标签'),
            content: AspectRatio(
              aspectRatio: 1.2 / 1,
              child: ListView(
                children: radioList,
              ),
            ),
          );
        });
      },
    );
  }

  List<Widget> _showTagAndAnimeCnt() {
    List<Widget> list = [];
    for (int i = 0; i < tags.length; ++i) {
      list.add(Column(
        children: [
          const SizedBox(
            height: 15,
          ),
          FutureBuilder(
            future: SqliteHelper.getInstance().getAnimeCntPerTag(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasError) {
                return const Icon(Icons.error);
              }
              if (snapshot.hasData) {
                List<int> animeCntPerTag = snapshot.data;
                return Text("${tags[i]} (${animeCntPerTag[i]})");
              }
              return const Text("");
            },
          ),
          const SizedBox(
            height: 15,
          ),
        ],
      ));
    }
    return list;
  }
}
