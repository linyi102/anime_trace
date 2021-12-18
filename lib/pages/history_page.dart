import 'package:flutter/material.dart';
import 'package:flutter_test_future/scaffolds/anime_sql_detail.dart';
import 'package:flutter_test_future/sql/history_sql.dart';
import 'package:flutter_test_future/sql/sqlite_helper.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  SqliteHelper sqliteHelper = SqliteHelper.getInstance();

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thickness: 5,
      radius: const Radius.circular(10),
      child: RefreshIndicator(
        // 下拉刷新
        onRefresh: () async {
          setState(() {});
        },
        child: FutureBuilder(
          future: sqliteHelper.getAllHistory(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            // 有错误时显示
            if (snapshot.hasError) {
              return Text(snapshot.hasError.toString());
            }
            // 有数据时显示
            if (snapshot.hasData) {
              List<HistorySql> history = [];

              history = snapshot.data;
              Map<String, List<HistorySql>> map =
                  {}; // 不能作为全局，否则r重载后，会在原来基础上再次添加

              for (int i = 0; i < history.length; ++i) {
                String ymd = history[i].getDate();
                // debugPrint("ymd=$ymd");
                if (!map.containsKey(ymd)) {
                  // 必须要先为List<>创建空间，才能添加元素
                  // 必须要先判断是否包含key，否则会清空之前刚添加的数据
                  map[ymd] = [];
                }
                map[ymd]!.add(history[i]);
              }

              List<Widget> list = [];
              map.forEach((key, value) {
                list.add(
                  ListTile(
                    title: Text(
                      key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      children: _getDayHistoryList(value),
                    ),
                  ),
                );
              });
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (BuildContext context, int index) {
                  return list[index];
                },
              );
            }
            // 加载时显示
            return const Text("");
          },
        ),
      ),
    );
  }

  List<Widget> _getDayHistoryList(List<HistorySql> history) {
    List<Widget> list = [];
    for (int i = 0; i < history.length; ++i) {
      list.add(
        ListTile(
          title: Text(
            history[i].animeName,
            style: const TextStyle(
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: Text("第${history[i].episodeNumber}集"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AnimeDetailPlus(history[i].animeId),
              ),
            );
          },
        ),
      );
    }
    return list;
  }
}
