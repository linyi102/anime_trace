import 'package:animetrace/dao/episode_desc_dao.dart';
import 'package:animetrace/models/note.dart';
import 'package:animetrace/utils/time_util.dart';

class Episode {
  final int _number; // 第几集
  String? dateTime; // 完成日期，若未完成，则是null
  int reviewNumber;
  int startNumber;

  Note? note; // 用于动漫详情页存放
  bool noteLoaded; // 用于记录笔记是否已查询过数据库

  EpisodeDesc? desc; // 动漫详情页存放描述

  Episode(
    this._number,
    this.reviewNumber, {
    this.startNumber = 1,
    this.dateTime,
    this.note,
    this.noteLoaded = false,
    this.desc,
  });

  // void setDateTimeNow() {
  //   dateTime = DateTime.now();
  // }

  void cancelDateTime() {
    dateTime = null;
  }

  int get number => _number;
  int get numberWithStartNumber => _number + startNumber - 1;

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

  /// 根据number和desc生成标题
  String get caption {
    String defaultTitle = "第 $numberWithStartNumber 集";
    if (desc == null) return defaultTitle;

    if (desc!.hideDefault) {
      return desc!.title;
    } else {
      return "$defaultTitle ${desc!.title}";
    }
  }
}
