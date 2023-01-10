import 'package:flutter/material.dart';

enum PlayStatus {
  unknown("状态", Icons.device_unknown),
  notStarted("未开播", Icons.lock_outline),
  playing("连载中", Icons.access_time),
  finished("已完结", Icons.check);

  final String text;
  final IconData iconData;

  const PlayStatus(this.text, this.iconData);
}
