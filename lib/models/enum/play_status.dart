import 'package:flutter/material.dart';

enum PlayStatus {
  unknown("未知", Icons.not_interested),
  notStarted("未开播", Icons.lock_outline),
  playing("连载中", Icons.access_time),
  finished("已完结", Icons.check);

  final String text;
  final IconData iconData;

  const PlayStatus(this.text, this.iconData);

  static PlayStatus text2PlayStatus(String text) {
    if (text.contains("完结")) {
      return PlayStatus.finished;
    } else if (text.contains("未知")) {
      return PlayStatus.unknown;
    } else if (text.contains("未")) {
      return PlayStatus.notStarted;
    } else if (text.contains("第") || text.contains("连载")) {
      return PlayStatus.playing;
    } else {
      return PlayStatus.unknown;
    }
  }

  static String toWhereSql(PlayStatus? playStatus) {
    switch (playStatus) {
      case PlayStatus.unknown:
        return '(play_status is null or play_status = "" or play_status = "未知")';
      case PlayStatus.notStarted:
        return 'play_status like "未%"';
      case PlayStatus.playing:
        return 'play_status like "%第%" or play_status like "%连载%"';
      case PlayStatus.finished:
        return 'play_status like "%完结%"';
      default:
        return '';
    }
  }
}
