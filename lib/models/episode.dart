import 'package:flutter_test_future/utils/time_show_util.dart';

class Episode {
  final int _number; // 第几集
  String? dateTime; // 完成日期，若未完成，则是null
  int reviewNumber;

  Episode(this._number, this.reviewNumber, {this.dateTime});

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
    return TimeShowUtil.getHumanReadableDateTimeStr(dateTime.toString());
  }
}
