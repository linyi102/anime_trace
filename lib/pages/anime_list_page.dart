import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/scaffolds/tabs.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
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
            future: SqliteUtil.getAllAnimeBytag(tags[i]),
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
                animes = snapshot.data as List<Anime>;
                return ListView.builder(
                  itemCount: animes.length,
                  itemBuilder: (BuildContext context, int index) {
                    // debugPrint("index=${index.toString()}");
                    Anime anime = animes[index];
                    return AnimeItem(anime);
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
        color: const Color.fromRGBO(250, 250, 250, 1),
        child: TabBarView(
          controller: _tabController,
          children: _getAnimeList(),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.search_outlined),
      //   onPressed: () => showSearch(
      //       context: context,
      //       delegate: SearchPage<Anime>(
      //         items: animes,
      //         builder: (anime) => AnimeItem(anime),
      //         failure: const Center(
      //           child: Text('No person found :('),
      //         ),
      //         filter: (anime) => [
      //           anime.animeName,
      //         ],
      //       )),
      // ),
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
                  SqliteUtil.insertAnime(Anime(
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
          content: AspectRatio(
            aspectRatio: 0.9 / 1,
            child: ListView(
              children: radioList,
            ),
          ),
        );
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
            future: SqliteUtil.getAnimeCntPerTag(),
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

class AnimeItem extends StatelessWidget {
  final Anime anime;
  const AnimeItem(
    this.anime, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        anime.animeName,
        style: const TextStyle(
          fontSize: 15,
          fontFamily: 'NotoSans',
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AnimeDetailPlus(anime.animeId),
          ),
        );
      },
      onLongPress: () {},
    );
  }
}
