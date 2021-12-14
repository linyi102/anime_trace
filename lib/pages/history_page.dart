import 'package:flutter/material.dart';
import 'package:flutter_test_future/scaffolds/anime_detail_scaffold.dart';
import 'package:flutter_test_future/utils/day_record.dart';
import 'package:flutter_test_future/utils/history_util.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  HistoryUtil historyUtil = HistoryUtil.getInstance();

  List<Widget> _getHistoryList() {
    // 获取所有日期
    List<String> dates = historyUtil.getAllDate();
    // debugPrint(dates.toString());

    List<Widget> historyList = [];
    // 获取该日期的所有动漫记录
    for (int i = 0; i < (dates.length > 10 ? 10 : dates.length); ++i) {
      int index = dates.length - 1 - i; // 倒序
      historyList.add(
        ListTile(
          title: Row(
            children: [
              const Icon(Icons.calendar_today),
              const SizedBox(
                width: 10,
              ),
              Text(
                dates[index],
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ],
          ),
          subtitle: Column(
            children: _getDayHistoryList(dates[index]),
          ),
        ),
      );
    }
    return historyList;
  }

  List<Widget> _getDayHistoryList(String date) {
    List<Widget> dayHistoryList = [];
    List<AnimeAndEpisode> animeRecord =
        historyUtil.dayRecords[date]!.animeRecord;
    for (int i = animeRecord.length - 1; i >= 0; --i) {
      AnimeAndEpisode e = animeRecord[i];
      dayHistoryList.add(ListTile(
        title: Text(e.anime.name),
        trailing: Text("第${e.episodeNumber}话"),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AnimalDetail(e.anime),
            ),
          );
        },
      ));
    }
    return dayHistoryList;
    // var tmpList = .map((e) {
    //   return ListTile(
    //     title: Text(e.anime.name),
    //     subtitle: Text("第${e.episodeNumber}话"),
    //   );
    // });
    // return tmpList.toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: _getHistoryList(),
    );
  }
}
