import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late String _modifiedTagName; // 用于记录临时切换的标签，点击确认后才会更新anime的标签

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  void _loadData() async {
    Future(() async {
      return await SqliteUtil.getAnimeByAnimeId(
          widget.animeId); // 一定要return，value才有值
    }).then((value) async {
      _anime = value;
      _modifiedTagName = _anime.tagName;
      debugPrint(value.toString());
      _episodes = await SqliteUtil.getAnimeEpisodeHistoryById(_anime);
    }).then((value) {
      _loadOk = true;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        debugPrint("按返回键，返回anime");
        for (var episode in _episodes) {
          if (episode.isChecked()) _anime.checkedEpisodeCnt++; // 用于传回
        }
        Navigator.pop(context, _anime);
        debugPrint("返回true");
        return true;
      },
      child: Scaffold(
        // backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                debugPrint("按返回按钮，返回anime");
                Navigator.pop(context, _anime);
              },
              icon: const Icon(Icons.arrow_back_rounded)),
        ),
        body: _loadOk
            ? Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  _displayAnimeName(),
                  const SizedBox(
                    height: 30,
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
    return Row(
      // mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 20,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
            child: Text(
              _anime.animeName,
              style: const TextStyle(
                fontSize: 20,
                // Row溢出部分省略号...表示，需要外套Expanded
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            _dialogUpdateAnime();
          },
          icon: const Icon(Icons.mode_edit_outline_outlined),
        ),
        const SizedBox(
          width: 15,
        ),
      ],
    );
  }

  _displayEpisode() {
    List<Widget> list = [];
    for (int i = 0; i < _episodes.length; ++i) {
      list.add(
        ListTile(
          onLongPress: () {},
          title: Text("第 ${_episodes[i].number} 集"),
          subtitle: Text(_episodes[i].getDate()),
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
        ),
      );
    }
    return Expanded(
      child: ListView(
        children: list,
      ),
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

  void _dialogUpdateAnime() async {
    // String anime.tagName =
    //     (await SqliteHelper.getTagNameByAnimeId(widget.animeId) as String);
    var inputNameController = TextEditingController();
    var inputEndEpisodeController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setTagStateOnAddAnime) {
          return AlertDialog(
            title: const Text('修改动漫'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: inputNameController..text = _anime.animeName,
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
                      ..text = "${_anime.animeEpisodeCnt}",
                    decoration: const InputDecoration(
                      labelText: "动漫集数",
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
                  _modifiedTagName,
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
                  Anime newAnime = Anime(
                      animeId: _anime.animeId,
                      animeName: name,
                      animeEpisodeCnt: endEpisode,
                      tagName: _modifiedTagName,
                      checkedEpisodeCnt: _anime.checkedEpisodeCnt);
                  SqliteUtil.updateAnime(_anime, newAnime); // 因为切换标签后

                  if (_anime.animeEpisodeCnt != endEpisode) {
                    _anime = newAnime; // 先判断，再检查
                    Future(() async {
                      // 获取新的集数
                      return SqliteUtil.getAnimeEpisodeHistoryById(_anime);
                    }).then((value) {
                      _episodes = value;
                      // 然后更新页面
                      setState(() {});
                    });
                  } else {
                    _anime = newAnime;
                    // 只是更新了名字，也需要更新页面
                    setState(() {});
                  }
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
              leading: tags[i] == _modifiedTagName
                  ? const Icon(
                      Icons.radio_button_on_outlined,
                      color: Colors.blue,
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                _modifiedTagName = tags[i];
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
}
