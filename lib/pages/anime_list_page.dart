import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/scaffolds/anime_detail_scaffold.dart';
import 'package:flutter_test_future/utils/anime.dart';
import 'package:flutter_test_future/utils/anime_list_util.dart';
import 'package:flutter_test_future/utils/tags.dart';

class AnimeListPage extends StatefulWidget {
  const AnimeListPage({Key? key}) : super(key: key);

  @override
  _AnimeListPageState createState() => _AnimeListPageState();
}

class _AnimeListPageState extends State<AnimeListPage>
    with SingleTickerProviderStateMixin {
  AnimeListUtil animeListUtil = AnimeListUtil.getInstance();
  late TabController _tabController;
  String addAnimeTag = tags[0];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Widget> _getAnimeList(String tag) {
    var tmpList = animeListUtil.getAnimeListByTag(tag)!.map((e) {
      return Column(
        children: [
          ListTile(
            title: Text(
              e.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis, // 避免名字过长，导致显示多行
            ),
            trailing: Text(
              e.getPace(),
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AnimalDetail(e),
                ),
              );
            },
          ),
          // const Divider(),
        ],
      );
      // return Card(
      //   // shadowColor: Colors.grey,
      //   // shadowColor: Colors.transparent,
      //   child: MaterialButton(
      //     // highlightColor: Colors.white,
      //     onPressed: () {
      //       Navigator.of(context).push(
      //         MaterialPageRoute(
      //           builder: (context) => AnimalDetail(e),
      //         ),
      //       );
      //     },
      //     child: AspectRatio(
      //       aspectRatio: 10 / 1,
      //       child: Stack(
      //         children: [
      //           Positioned(
      //             left: 10,
      //             top: 20,
      //             child: Text(
      //               e.name,
      //               style: const TextStyle(fontSize: 18),
      //             ),
      //           ),
      //           Positioned(
      //             top: 20,
      //             right: 10,
      //             child: Text(
      //               e.getPace(),
      //               style: const TextStyle(fontSize: 15),
      //             ),
      //             // child: Text("${e.lastCheckedEpisode}/${e.episodes.length}"),
      //           ),
      //         ],
      //       ),
      //     ),
      //   ),
      // );
    });
    return tmpList.toList();
  }

  @override
  Widget build(BuildContext context) {
    // return ListView(
    //   children: _getAnimeList(),
    // );
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
          tabs: [
            TagTab(tags[0]),
            TagTab(tags[1]),
            TagTab(tags[2]),
            TagTab(tags[3]),
            TagTab(tags[4]),
          ],
          controller: _tabController,
        ),
      ),
      body: Container(
        color: Colors.white, // 使用函数设置颜色没有效果，很奇怪
        child: TabBarView(
          controller: _tabController,
          children: [
            ListView(
              children: _getAnimeList(tags[0]),
            ),
            ListView(
              children: _getAnimeList(tags[1]),
            ),
            ListView(
              children: _getAnimeList(tags[2]),
            ),
            ListView(
              children: _getAnimeList(tags[3]),
            ),
            ListView(
              children: _getAnimeList(tags[4]),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _alertAddAnime();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _alertAddAnime() {
    var inputNameController = TextEditingController();
    var inputEndEpisodeController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String _labelTextInEpisodeField = "动漫集数：12";
        return StatefulBuilder(builder: (context, setTagStateOnAddAnime) {
          return AlertDialog(
            title: const Text('添加漫画'),
            content: AspectRatio(
              aspectRatio: 2 / 1,
              child: Column(
                children: [
                  TextField(
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
                  _alertSelectTag(setTagStateOnAddAnime);
                },
                icon: const Icon(
                  Icons.new_label,
                  size: 26,
                  color: Colors.blue,
                ),
                label: Text(
                  addAnimeTag,
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
                  // 设置动漫的名称、标签和集数
                  Anime anime = Anime(name, tag: addAnimeTag);
                  anime.setEndEpisode(endEpisode);
                  // 改变状态
                  setState(() {
                    animeListUtil.addAnime(anime);
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
  void _alertSelectTag(setTagStateOnAddAnime) {
    int groupValue = tags.indexOf(addAnimeTag); // 默认选择
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
                        addAnimeTag = tags[i];
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
              aspectRatio: 1.47 / 1,
              child: Column(
                children: radioList,
              ),
            ),
          );
        });
      },
    );
  }
}

class TagTab extends StatelessWidget {
  final String _tabName;
  const TagTab(this._tabName, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 15,
        ),
        Text(_tabName),
        const SizedBox(
          height: 15,
        ),
      ],
    );
  }
}
