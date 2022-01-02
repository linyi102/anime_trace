import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/scaffolds/anime_climb.dart';
import 'package:flutter_test_future/scaffolds/tabs.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/classes/episode.dart';
import 'package:flutter_test_future/utils/tags.dart';
import 'package:oktoast/oktoast.dart';

class AnimeDetailPlus extends StatefulWidget {
  final int animeId;
  const AnimeDetailPlus(this.animeId, {Key? key}) : super(key: key);

  @override
  _AnimeDetailPlusState createState() => _AnimeDetailPlusState();
}

class _AnimeDetailPlusState extends State<AnimeDetailPlus> {
  late Anime _anime;
  List<Episode> _episodes = [];
  bool _loadOk = false;

  FocusNode blankFocusNode = FocusNode(); // 空白焦点
  FocusNode animeNameFocusNode = FocusNode(); // 动漫名字输入框焦点
  // FocusNode descFocusNode = FocusNode(); // 描述输入框焦点

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    Future(() async {
      return await SqliteUtil.getAnimeByAnimeId(
          widget.animeId); // 一定要return，value才有值
    }).then((value) async {
      _anime = value;
      debugPrint(value.toString());
      _episodes = await SqliteUtil.getAnimeEpisodeHistoryById(_anime);
    }).then((value) {
      _loadOk = true;
      setState(() {});
    });
  }

  // 用于传回到动漫列表页
  void _refreshAnime() {
    for (var episode in _episodes) {
      if (episode.isChecked()) _anime.checkedEpisodeCnt++;
    }
    SqliteUtil.updateDescByAnimeId(_anime.animeId, _anime.animeDesc);
    SqliteUtil.updateAnimeNameByAnimeId(_anime.animeId, _anime.animeName);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        debugPrint("按返回键，返回anime");
        _refreshAnime();
        Navigator.pop(context, _anime);
        debugPrint("返回true");
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                debugPrint("按返回按钮，返回anime");
                _refreshAnime();
                Navigator.pop(context, _anime);
              },
              tooltip: "返回上一级",
              icon: const Icon(Icons.arrow_back_rounded)),
          title: !_loadOk
              ? Container()
              : ListTile(
                  title: Row(
                    children: [
                      Text(_anime.tagName),
                      const SizedBox(
                        width: 10,
                      ),
                      const Icon(Icons.expand_more_rounded),
                    ],
                  ),
                  onTap: () {
                    _dialogSelectTag();
                  },
                ),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (context) => AnimeClimb(
                                animeId: _anime.animeId,
                                keyword: _anime.animeName,
                              )))
                      .then((value) async {
                    _loadData();
                  });
                },
                tooltip: "搜索封面",
                icon: const Icon(Icons.image_search_rounded)),
            IconButton(
                onPressed: () {
                  _dialogUpdateEpisodeCnt();
                },
                tooltip: "更改集数",
                icon: const Icon(Icons.add)),
            IconButton(
                onPressed: () {
                  _dialogDeleteAnime();
                },
                tooltip: "删除动漫",
                icon: const Icon(Icons.delete)),
          ],
        ),
        body: _loadOk
            ? ListView(
                children: [
                  _displayAnimeCover(),
                  // _displayAnimeName(),
                  // _displayDesc(),
                  const SizedBox(
                    height: 10,
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
                    child: Divider(
                      thickness: 1,
                    ),
                  ),
                  _displayEpisode(),
                ],
              )
            : _waitDataBody(),
      ),
    );
  }

  _waitDataBody() {
    return Container();
  }

  _displayAnimeCover() {
    return Flex(direction: Axis.horizontal, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(15, 20, 0, 15),
        child: SizedBox(
          width: 110,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: AnimeGridCover(_anime),
          ),
        ),
      ),
      Expanded(
        child: Column(
          children: [
            _displayAnimeName(),
            _displayDesc(),
          ],
        ),
      )
    ]);
  }

  _displayAnimeName() {
    var animeNameTextEditingController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
      child: TextField(
        focusNode: animeNameFocusNode,
        maxLines: null, // 加上这个后，回车不会调用onEditingComplete
        controller: animeNameTextEditingController..text = _anime.animeName,
        style: const TextStyle(
          fontSize: 17,
          overflow: TextOverflow.ellipsis,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        onTap: () {},
        // 情况1：改完名字直接返回，此时需要onChanged来时刻监听输入的值，并改变_anime.animeName，然后在返回键和返回按钮中更新数据库并传回
        onChanged: (value) {
          _anime.animeName = value;
        },
        // 情况2：改完名字后回车，会直接保存到_anime.animeName和数据库中
        onEditingComplete: () {
          String newAnimeName = animeNameTextEditingController.text;
          debugPrint("失去焦点，动漫名称为：$newAnimeName");
          _anime.animeName = newAnimeName;
          SqliteUtil.updateAnimeNameByAnimeId(_anime.animeId, newAnimeName);
          FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
        },
      ),
    );
  }

  _displayDesc() {
    var descTextEditingController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      child: TextField(
        // focusNode: descFocusNode,
        maxLines: null,
        controller: descTextEditingController..text = _anime.animeDesc,
        decoration: const InputDecoration(
          hintText: "描述",
          border: InputBorder.none,
        ),
        style: const TextStyle(height: 1.5, fontSize: 16),
        onChanged: (value) {
          _anime.animeDesc = value;
        },
        // 因为设置的是无限行(可以回车换行)，所以怎样也不会执行onEditingComplete
        // onEditingComplete: () {
        //   debugPrint("失去焦点，动漫名称为：${descTextEditingController.text}");
        //   FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
        // },
      ),
    );
  }

  _displayEpisode() {
    List<Widget> list = [];
    for (int i = 0; i < _episodes.length; ++i) {
      list.add(
        ListTile(
          visualDensity: const VisualDensity(vertical: -2),
          // contentPadding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          title: Text("第 ${_episodes[i].number} 集"),
          subtitle: Text(_episodes[i].getDate()),
          // enabled: !_episodes[i].isChecked(), // 完成后会导致无法长按设置日期
          style: ListTileStyle.drawer,
          trailing: IconButton(
            onPressed: () {
              if (_episodes[i].isChecked()) {
                _dialogRemoveDate(
                  _episodes[i].number,
                  _episodes[i].dateTime,
                ); // 这个函数执行完毕后，在执行下面的setState并不会更新页面，因此需要在该函数中使用setState
              } else {
                String date = DateTime.now().toString();
                SqliteUtil.insertHistoryItem(
                    widget.animeId, _episodes[i].number, date);
                _episodes[i].dateTime = date;
                setState(() {});
              }
            },
            // icon: _episodes[i].isChecked()
            //     ? const Icon(
            //         // Icons.check_box_outlined,
            //         Icons.check_rounded,
            //         color: Colors.grey,
            //       )
            //     : const Icon(
            //         Icons.check_box_outline_blank_rounded,
            //         color: Colors.black,
            //       ),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              transitionBuilder: (Widget child, Animation<double> animation) {
                //执行缩放动画
                return ScaleTransition(child: child, scale: animation);
              },
              child: _episodes[i].isChecked()
                  ? Icon(
                      // Icons.check_box_outlined,
                      Icons.check_rounded,
                      color: Colors.grey,
                      key: Key("$i"), // 不能用unique，否则同状态的按钮都会有动画
                    )
                  : const Icon(
                      Icons.check_box_outline_blank_rounded,
                      color: Colors.black,
                    ),
            ),
          ),
          onTap: () {
            FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
          },
          onLongPress: () async {
            DateTime defaultDateTime = DateTime.now();
            if (_episodes[i].isChecked()) {
              defaultDateTime = DateTime.parse(_episodes[i].dateTime as String);
            }
            String dateTime =
                await _showDatePicker(defaultDateTime: defaultDateTime);

            if (dateTime.isEmpty) return; // 没有选择日期，则直接返回

            // 选择日期后，如果之前有日期，则更新。没有则直接插入
            // 注意：对于_episodes[i]，它是第_episodes[i].number集
            int episodeNumber = _episodes[i].number;
            if (_episodes[i].isChecked()) {
              SqliteUtil.updateHistoryItem(
                  _anime.animeId, episodeNumber, dateTime);
            } else {
              SqliteUtil.insertHistoryItem(
                  _anime.animeId, episodeNumber, dateTime);
            }
            // 更新页面
            setState(() {
              // 改的是i，而不是episodeNumber
              _episodes[i].dateTime = dateTime;
            });
          },
        ),
      );
    }
    return Column(
      children: list,
    );
  }

  Future<String> _showDatePicker({DateTime? defaultDateTime}) async {
    var picker = await showDatePicker(
        context: context,
        initialDate: defaultDateTime ?? DateTime.now(), // 没有给默认时间时，设置为今天
        firstDate: DateTime(1986),
        lastDate: DateTime(DateTime.now().year + 2),
        locale: const Locale("zh"));
    return picker == null ? "" : picker.toString();
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
                Navigator.pop(context);
              },
              child: const Text('否'),
            ),
            TextButton(
              onPressed: () {
                SqliteUtil.deleteHistoryItemByAnimeIdAndEpisodeNumber(
                    _anime.animeId, episodeNumber);
                // 注意第1集是下标0
                _episodes[episodeNumber - 1].cancelDateTime();
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('是'),
            ),
          ],
        );
      },
    );
  }

  void _dialogSelectTag() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Widget> radioList = [];
        for (int i = 0; i < tags.length; ++i) {
          radioList.add(
            ListTile(
              title: Text(tags[i]),
              leading: tags[i] == _anime.tagName
                  ? const Icon(
                      Icons.radio_button_on_outlined,
                      color: Colors.blue,
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                _anime.tagName = tags[i];
                SqliteUtil.updateTagByAnimeId(_anime.animeId, _anime.tagName);
                debugPrint("修改标签为${_anime.tagName}");
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

  _dialogDeleteAnime() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("警告！"),
            content: const Text("确认删除该动漫吗？"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("取消")),
              TextButton(
                  onPressed: () {
                    SqliteUtil.deleteAnimeByAnimeId(_anime.animeId);
                    // 直接返回到主页
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const Tabs()),
                        (route) => false); // 返回false就没有左上角的返回按钮了
                  },
                  child: const Text(
                    "确认",
                    style: TextStyle(color: Colors.red),
                  )),
            ],
          );
        });
  }

  _dialogUpdateEpisodeCnt() {
    var episodeCntTextEditingController = TextEditingController();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("修改动漫集数"),
            content: TextField(
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // 数字，只能是整数
              ],
              controller: episodeCntTextEditingController
                ..text = _anime.animeEpisodeCnt.toString(),
              decoration: const InputDecoration(
                  border: InputBorder.none, labelText: "动漫集数"),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("取消")),
              TextButton(
                  onPressed: () {
                    String content = episodeCntTextEditingController.text;
                    if (content.isEmpty) {
                      showToast("集数不能为空！");
                      return;
                    }
                    int episodeCnt = int.parse(content);
                    SqliteUtil.updateEpisodeCntByAnimeId(
                        _anime.animeId, episodeCnt);

                    setState(() {
                      _anime.animeEpisodeCnt = episodeCnt;
                      // 少了就删除，多了就添加
                      var len = _episodes
                          .length; // 因为添加或删除时_episodes.length会变化，所以需要保存到一个变量中
                      if (len > episodeCnt) {
                        for (int i = 0; i < len - episodeCnt; ++i) {
                          // 还应该删除history表里的记录，否则会误判完成过的集数
                          SqliteUtil.deleteHistoryItemByAnimeIdAndEpisodeNumber(
                              _anime.animeId, _episodes.last.number);
                          // 注意顺序
                          _episodes.removeLast();
                        }
                      } else {
                        int number = _episodes.last.number;
                        for (int i = 0; i < episodeCnt - len; ++i) {
                          _episodes.add(Episode(number + i + 1));
                        }
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("确认")),
            ],
          );
        });
  }
}
