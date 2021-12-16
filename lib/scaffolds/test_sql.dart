import 'package:flutter/material.dart';
import 'package:flutter_test_future/sql/anime_sql.dart';
import 'package:flutter_test_future/sql/sqlite_helper.dart';

class TestSQL extends StatefulWidget {
  const TestSQL({Key? key}) : super(key: key);

  @override
  _TestSQLState createState() => _TestSQLState();
}

class _TestSQLState extends State<TestSQL> {
  SqliteHelper sqliteHelper = SqliteHelper.getInstance();
  List<AnimeSql> allAnimeInTag = [];
  List<String> allTag = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("DB Demo"),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              debugPrint(allTag.toString());
              debugPrint(allAnimeInTag.toString());
            },
            child: const Text("显示标签"),
          ),
          ElevatedButton(
            onPressed: () {
              AnimeSql anime = AnimeSql(
                animeName: "鬼灭之刃",
                animeEpisodeCnt: 12,
                tagName: "拾",
              );
              sqliteHelper.insertAnime(anime);
            },
            child: const Text("插入动漫"),
          ),
          ElevatedButton(
            onPressed: () async {
              var list = await sqliteHelper.getAllAnimeBytag("拾");
              // print(list.toList());
              setState(() {
                allAnimeInTag = list;
              });
            },
            child: const Text("获取某标签下的所有动漫"),
          ),
          Expanded(
            child: ListView(
              children: _getAllAnimeByTag(),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: sqliteHelper.getAllAnimeBytag("拾"),
              // future结束后会通知builder重新渲染画面，因此stateless也可以
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.hasError) {
                  debugPrint(snapshot.error.toString());
                  return const Icon(
                    Icons.error_outline,
                    size: 80,
                  );
                }
                if (snapshot.hasData) {
                  List<Widget> _getList() {
                    var tmpList = (snapshot.data as List<AnimeSql>).map((e) {
                      return ListTile(
                        title: Text(e.animeName),
                        trailing: Text(
                          "${e.checkedEpisodeCnt}/${e.animeEpisodeCnt}",
                        ),
                      );
                    });
                    return tmpList.toList();
                  }

                  return ListView(
                    children: _getList(),
                  );
                }
                // 等待数据时显示加载画面
                return const CircularProgressIndicator();
              },
            ),
          ),
        ],
      ),
    );
  }

  _getAllAnimeByTag() {
    var tmpList = allAnimeInTag.map((e) {
      return ListTile(
        title: Text(e.animeName),
        trailing: Text(
          "${e.checkedEpisodeCnt}/${e.animeEpisodeCnt}",
        ),
      );
    });
    return tmpList.toList();
  }
}
