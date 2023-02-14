import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/utils/time_util.dart';

class Episode {
  final int _number; // 第几集
  String? dateTime; // 完成日期，若未完成，则是null
  int reviewNumber;

  Note? note; // 用于动漫详情页存放
  bool noteLoaded; // 用于记录笔记是否已查询过数据库

  Episode(this._number, this.reviewNumber,
      {this.dateTime, this.note, this.noteLoaded = false});

  // void setDateTimeNow() {
  //   dateTime = DateTime.now();
  // }

  void cancelDateTime() {
    dateTime = null;
  }

  int get number => _number;

  bool isChecked() {
    return dateTime == null ? false : true;
  }

  String getDate() {
    if (dateTime == null) return "";
    // 2022-09-04 00:00:00.000Z
    // String date = dateTime!.split(' ')[0]; // 2022-09-04
    // return date.replaceAll("-", "/"); // 2022/09/04
    return TimeUtil.getHumanReadableDateTimeStr(dateTime.toString());
  }
}
