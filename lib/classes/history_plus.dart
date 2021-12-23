import 'package:flutter_test_future/classes/record.dart';

class HistoryPlus {
  String date;
  List<Record> records;

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
