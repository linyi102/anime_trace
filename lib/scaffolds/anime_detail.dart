import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/classes/episode.dart';
import 'package:flutter_test_future/utils/tags.dart';

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
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                debugPrint("按返回按钮，返回anime");
                _refreshAnime();
                Navigator.pop(context, _anime);
              },
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
                    _dialogSelectTag(context);
                  },
                ),
        ),
        body: _loadOk
            ? ListView(
                children: [
                  _displayAnimeName(),
                  _displayDesc(),
                  const SizedBox(
                    height: 10,
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Divider(),
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

  _displayAnimeName() {
    var animeNameTextEditingController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
      child: TextField(
        focusNode: animeNameFocusNode,
        // maxLines: null, // 加上这个后，回车不会调用onEditingComplete
        controller: animeNameTextEditingController..text = _anime.animeName,
        style: const TextStyle(fontSize: 20, overflow: TextOverflow.ellipsis),
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
        style: const TextStyle(height: 1.5),
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
            icon: _episodes[i].isChecked()
                ? const Icon(
                    // Icons.check_box_outlined,
                    Icons.check_rounded,
                    color: Colors.grey,
                  )
                : const Icon(
                    Icons.check_box_outline_blank_rounded,
                    color: Colors.black,
                  ),
          ),
          onLongPress: () {},
          onTap: () {
            FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
          },
        ),
      );
    }
    return Column(
      children: list,
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
                Navigator.pop(context);
              },
              child: const Text('否'),
            ),
            TextButton(
              onPressed: () {
                SqliteUtil.deleteHistoryItem(
                    date, widget.animeId, episodeNumber);
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

  // 传入动漫对话框的状态，选择好标签后，就会更新该状态
  void _dialogSelectTag(parentContext) {
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
                SqliteUtil.updateTagNameByAnimeId(
                    _anime.animeId, _anime.tagName);
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
}
