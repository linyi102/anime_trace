import 'package:flutter_test_future/utils/anime.dart';
import 'package:flutter_test_future/utils/day_record.dart';

class HistoryUtil {
  // 单例模式
  static HistoryUtil? _single;

  HistoryUtil._();

  static HistoryUtil getInstance() {
    return _single ??= HistoryUtil._();
  }

  // 日期-当天观看的动漫和集数
  Map<String, DayRecord> dayRecords = {};

  void addRecord(String date, Anime anime, int episodeNumber) {
    if (dayRecords[date] == null) {
      // 第一次没有对应的键值对，因此需要先添加。而且只是在null时用，否则会每次都会清空之前的记录
      dayRecords[date] = DayRecord();
    }
    dayRecords[date]!.addRecord(anime, episodeNumber);
  }

  void removeRecord(String date, Anime anime, int episodeNumber) {
    if (dayRecords[date] == null) {
      print("👉date=$date");
      print("👉不可能：dayRecords[date] == null");
      return;
    }
    dayRecords[date]!.removeRecord(anime, episodeNumber);
  }

  List<String> getAllDate() {
    return dayRecords.keys.toList();
  }

  void showHistory() {
    for (String date in dayRecords.keys) {
      print(dayRecords[date].toString());
    }
  }
}
