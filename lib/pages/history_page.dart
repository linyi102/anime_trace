import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/classes/history_plus.dart';
import 'package:flutter_test_future/classes/record.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:oktoast/oktoast.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  Map<int, List<HistoryPlus>> yearHistory = {};
  Map<int, bool> yearLoadOk = {};
  int curYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadData(curYear);
  }

  _loadData(int year) async {
    debugPrint("加载$year年数据中...");
    Future(() async {
      return await SqliteUtil.getAllHistoryByYear(year);
    }).then((value) {
      debugPrint("$year年数据加载完成");
      yearHistory[year] = value;
      yearLoadOk[year] = true;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thickness: 5,
      radius: const Radius.circular(10),
      child: RefreshIndicator(
        // 下拉刷新
        onRefresh: () async {
          _loadData(curYear);
        },
        child: !yearLoadOk.containsKey(curYear)
            ? Container(
                color: Colors.white,
              )
            : _getHistoryListView(),
      ),
    );
  }

  Widget _getHistoryListView() {
    // if (historyPlus.isEmpty) {
    //   return ListView(
    //     // 必须是ListView，不然向下滑不会有刷新
    //     children: const [],
    //   );
    // }
    return Stack(children: [
      Container(
        color: Colors.white,
        child: ListView.separated(
          itemCount: yearHistory[curYear]!.length,
          itemBuilder: (BuildContext context, int index) {
            // debugPrint("$index");
            return ListTile(
              contentPadding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
              title: ListTile(
                title: Text(yearHistory[curYear]![index].date),
              ),
              subtitle: Column(
                children: _getRecord(index),
              ),
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider();
          },
        ),
      ),
      Container(
        alignment: Alignment.bottomCenter,
        child: AspectRatio(
          aspectRatio: 4.5 / 1,
          child: Card(
            elevation: 0,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(50))), // 圆角
            clipBehavior: Clip.antiAlias, // 设置抗锯齿，实现圆角背景
            color: const Color.fromRGBO(0, 118, 243, 0.1),
            margin: const EdgeInsets.fromLTRB(50, 20, 50, 20),
            child: Row(
              children: [
                Expanded(
                  child: IconButton(
                      onPressed: () {
                        curYear--;
                        // 没有加载过，才去查询数据库
                        if (!yearLoadOk.containsKey(curYear)) {
                          debugPrint("之前未查询过$curYear年，现查询");
                          _loadData(curYear);
                        } else {
                          // 加载过，直接更新状态
                          debugPrint("查询过$curYear年，直接更新状态");
                          setState(() {});
                        }
                      },
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: Colors.blueGrey,
                      )),
                ),
                Expanded(
                  child: TextButton(
                      onPressed: () {
                        _dialogSelectYear();
                      },
                      child: Text(
                        "$curYear",
                        style: const TextStyle(
                            fontSize: 18, color: Colors.blueGrey),
                      )),
                ),
                Expanded(
                  child: IconButton(
                      onPressed: () {
                        curYear++;
                        // 没有加载过，才去查询数据库
                        if (!yearLoadOk.containsKey(curYear)) {
                          debugPrint("之前未查询过$curYear年，现查询");
                          _loadData(curYear);
                        } else {
                          // 加载过，直接更新状态
                          debugPrint("查询过$curYear年，直接更新状态");
                          setState(() {});
                        }
                      },
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Colors.blueGrey,
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  List<Widget> _getRecord(int index) {
    List<Widget> listWidget = [];
    List<Record> records = yearHistory[curYear]![index].records;
    for (var record in records) {
      listWidget.add(
        ListTile(
          visualDensity: const VisualDensity(vertical: -3),
          title: Text(
            record.anime.animeName,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: record.startEpisodeNumber == record.endEpisodeNumber
              ? Text("${record.startEpisodeNumber}")
              : Text("${record.startEpisodeNumber}-${record.endEpisodeNumber}"),
          onTap: () {
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (context) => AnimeDetailPlus(record.anime.animeId),
              ),
            )
                .then((value) {
              _loadData(curYear);
            });
          },
        ),
      );
    }
    return listWidget;
  }

  _dialogSelectYear() {
    var yearTextEditingController = TextEditingController();
    int tmpYear = curYear;
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, state) {
            return AlertDialog(
                title: const Text("选择年份"),
                content: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        // autofocus: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly, // 数字，只能是整数
                        ],
                        controller: yearTextEditingController
                          ..text = tmpYear.toString(),
                        decoration:
                            const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          tmpYear--;
                          state(() {});
                        },
                        icon: const Icon(Icons.navigate_before)),
                    IconButton(
                        onPressed: () {
                          tmpYear++;
                          state(() {});
                        },
                        icon: const Icon(Icons.navigate_next)),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("取消")),
                  TextButton(
                      onPressed: () {
                        String content = yearTextEditingController.text;
                        if (content.isEmpty) {
                          showToast("年份不能为空！");
                          return;
                        }
                        curYear = int.parse(content);
                        _loadData(curYear);
                        Navigator.pop(context);
                      },
                      child: const Text("确认")),
                ]);
          });
        });
  }
}
