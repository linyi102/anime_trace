import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/history_plus.dart';
import 'package:flutter_test_future/classes/record.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:proste_route_animation/proste_route_animation.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HistoryPlus> historyPlus = [];
  bool _loadOk = false;
  int _pageIndex = 1;
  final int _pageSize = 100;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    debugPrint("历史页面：加载数据");
    Future(() async {
      return await SqliteUtil.getAllHistoryPlus();
    }).then((value) {
      debugPrint("历史页面：加载完成");
      historyPlus = value;
      _loadOk = true;
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
          Future(() async {
            return await SqliteUtil.getAllHistoryPlus();
          }).then((value) {
            debugPrint("加载完成");
            historyPlus = value;
            setState(() {});
          });
        },
        child: !_loadOk
            ? Container(
                // color: const Color.fromRGBO(250, 250, 250, 1),
                color: Colors.white,
              )
            : _getChildPlus(),
      ),
    );
  }

  Widget _getChildPlus() {
    // if (historyPlus.isEmpty) {
    //   return ListView(
    //     // 必须是ListView，不然向下滑不会有刷新
    //     children: const [],
    //   );
    // }
    return Container(
      // color: const Color.fromRGBO(250, 250, 250, 1),
      color: Colors.white,
      child: ListView.separated(
        itemCount: historyPlus.length,
        itemBuilder: (BuildContext context, int index) {
          // debugPrint("$index");
          return ListTile(
            contentPadding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
            title: ListTile(
              title: Text(historyPlus[index].date),
            ),
            subtitle: Column(
              children: _getColumn(index),
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return const Divider();
        },
      ),
    );
  }

  List<Widget> _getColumn(int index) {
    List<Widget> listWidget = [];
    List<Record> records = historyPlus[index].records;
    for (var record in records) {
      listWidget.add(
        ListTile(
          title: Text(
            record.anime.animeName,
            overflow: TextOverflow.ellipsis,
          ),
          trailing:
              Text("${record.startEpisodeNumber}-${record.endEpisodeNumber}"),
          onTap: () {
            Navigator.push(
                context,
                ProsteRouteAnimation.fadeRoute(
                  route: AnimeDetailPlus(record.anime.animeId),
                  duration: const Duration(milliseconds: 0),
                  reverseDuration: const Duration(milliseconds: 0),
                  curve: Curves.linear,
                )).then((value) {
              _loadData();
            });
            // Navigator.of(context)
            //     .push(
            //   MaterialPageRoute(
            //     builder: (context) => AnimeDetailPlus(record.anime.animeId),
            //   ),
            // )
            //     .then((value) {
            //   _loadData();
            // });
          },
        ),
      );
    }
    return listWidget;
  }
}
