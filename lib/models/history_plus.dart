import 'package:animetrace/models/anime_history_record.dart';

class HistoryPlus {
  String date;
  List<AnimeHistoryRecord> records;

  HistoryPlus(this.date, this.records);

  @override
  String toString() {
    StringBuffer res = StringBuffer();
    for (var item in records) {
      res.writeln(item);
    }
    return "📅 $date:\n$res";
  }
}
