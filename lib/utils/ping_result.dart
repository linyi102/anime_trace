import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/theme_util.dart';

class PingStatus {
  bool pinging; // 正在ping
  bool needPing; // 需要ping
  bool connectable; // 可以连接
  int time;

  PingStatus(
      {this.connectable = false,
      this.time = -1,
      this.pinging = false,
      this.needPing = true});

  Color get color => (needPing || pinging)
      ? Colors.grey // 需要ping，或者正在ping
      : (connectable ? ThemeUtil.getConnectableColor() : Colors.red);

  @override
  String toString() {
    return "PingStatus[ok=$connectable, time=$time]";
  }
}
