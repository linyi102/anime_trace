import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/sql/anime_sql.dart';
import 'package:flutter_test_future/sql/sqlite_helper.dart';
import 'package:flutter_test_future/utils/episode.dart';
import 'package:flutter_test_future/utils/tags.dart';

class AnimeDetailPlus extends StatefulWidget {
  final int animeId;
  const AnimeDetailPlus(this.animeId, {Key? key}) : super(key: key);

  @override
  _AnimeDetailPlusState createState() => _AnimeDetailPlusState();
}

class _AnimeDetailPlusState extends State<AnimeDetailPlus> {
  SqliteHelper sqliteHelper = SqliteHelper.getInstance();
  late AnimeSql anime;
  late List<Episode> episodes;

  @override
  void initState() {
    super.initState();
    _getInitAnime();
  }

  void _getInitAnime() async {
    anime = await sqliteHelper.getAnimeById(widget.animeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.transparent,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: Column(
        children: [
          ElevatedButton(
              onPressed: () => _dialogUpdateAnime(), child: const Text("更新")),
          const SizedBox(
            height: 10,
          ),
          _displayAnimeName(),
          const SizedBox(
            height: 30,
          ),
          _displayEpisode(),
        ],
      ),
    );
  }

  _displayAnimeName() {
    return FutureBuilder(
      future: sqliteHelper.getAnimeById(widget.animeId),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasError) {
          debugPrint(snapshot.error.toString());
          return const Icon(
            Icons.error,
            size: 80,
          );
        }
        if (snapshot.hasData) {
          anime = snapshot.data as AnimeSql; // 设置获取的动漫
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 20,
              ),
              Expanded(
                flex: 10,
                child: Text(
                  anime.animeName,
                  style: const TextStyle(
                    fontSize: 20,
                    // Row溢出部分省略号...表示，需要外套Expanded
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        }
        return const CircularProgressIndicator();
        // return const Text("");
      },
    );
  }

  _displayEpisode() {
    return FutureBuilder(
      future: sqliteHelper.getAnimeEpisodeHistoryById(widget.animeId),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasError) {
          debugPrint(snapshot.error.toString());
          return const Icon(
            Icons.error,
            size: 80,
          );
        }
        if (snapshot.hasData) {
          episodes = snapshot.data as List<Episode>; // 设置获取的集状态
          // for (var item in episodes) {
          //   debugPrint(item.dateTime);
          // }
          List<Widget> list = [];
          for (int i = 0; i < episodes.length; ++i) {
            list.add(ListTile(
              title: Text("第${episodes[i].number}集"),
              subtitle: Text(episodes[i].getDate()),
              trailing: ElevatedButton(
                onPressed: () {
                  if (episodes[i].isChecked()) {
                    _dialogRemoveDate(
                      episodes[i].number,
                      episodes[i].dateTime,
                    ); // 这个函数执行完毕后，在执行下面的setState并不会更新页面，因此需要在该函数中使用setState
                  } else {
                    sqliteHelper.insertHistoryItem(
                      widget.animeId,
                      episodes[i].number,
                    );
                    setState(() {});
                  }
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.white),
                  foregroundColor: MaterialStateProperty.all(Colors.black),
                  shadowColor: MaterialStateProperty.all(Colors.transparent),
                  minimumSize: MaterialStateProperty.all(
                    const Size(0, 0),
                  ),
                  maximumSize: MaterialStateProperty.all(
                    const Size(20, 20),
                  ),
                ),
                child: episodes[i].isChecked()
                    ? const Icon(
                        // Icons.check_box_outlined,
                        Icons.check_rounded,
                        color: Colors.grey,
                      )
                    : const Icon(Icons.check_box_outline_blank_rounded),
              ),
            ));
          }
          return Expanded(
              child: ListView(
            children: list,
          ));
        }
        return const CircularProgressIndicator();
        // return const Text("");
      },
    );
  }

  void _dialogRemoveDate(int episodeNumber, String? date) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('是否撤销日期?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                sqliteHelper.removeHistoryItem(date);
                setState(() {});
                Navigator.pop(context); // bug：没有弹出
              },
              child: const Text('是'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('否'),
            ),
          ],
        );
      },
    );
  }

  void _dialogUpdateAnime() async {
    // String anime.tagName =
    //     (await sqliteHelper.getTagNameByAnimeId(widget.animeId) as String);
    var inputNameController = TextEditingController();
    var inputEndEpisodeController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setTagStateOnAddAnime) {
          return AlertDialog(
            title: const Text('修改动漫'),
            content: AspectRatio(
              aspectRatio: 2 / 1,
              child: Column(
                children: [
                  TextField(
                    controller: inputNameController..text = anime.animeName,
                    decoration: const InputDecoration(
                      labelText: "动漫名称",
                      border: InputBorder.none,
                    ),
                  ),
                  TextField(
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    controller: inputEndEpisodeController
                      ..text = "${anime.animeEpisodeCnt}",
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
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
                  anime.tagName,
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
                  sqliteHelper.modifyAnime(
                    // 不能传anime.animeId，因为没有数据
                    widget.animeId,
                    AnimeSql(
                      animeName: name,
                      animeEpisodeCnt: endEpisode,
                      tagName: anime.tagName,
                    ),
                  );
                  setState(() {});
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
    int groupValue = tags.indexOf(anime.tagName); // 默认选择
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
                        anime.tagName = tags[i];
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
