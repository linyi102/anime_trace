import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

enum PlayStatus {
  unknown("未知", EvaIcons.questionMark),
  notStarted("未开播", Icons.lock_outline),
  playing("连载中", Icons.access_time),
  finished("已完结", Icons.check);

  final String text;
  final IconData iconData;

  const PlayStatus(this.text, this.iconData);
}
