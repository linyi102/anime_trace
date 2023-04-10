import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/models/ping_result.dart';

buildPingStatusRow(BuildContext context, ClimbWebsite climbWebsite,
    {bool gridStyle = false}) {
  var textStyle = Theme.of(context).textTheme.caption?.copyWith(height: 1.1);
  return Row(
    mainAxisAlignment:
        gridStyle ? MainAxisAlignment.center : MainAxisAlignment.start,
    children: [
      climbWebsite.discard
          ? _getPingStatusIcon(PingStatus())
          : _getPingStatusIcon(climbWebsite.pingStatus),
      const SizedBox(width: 4),
      climbWebsite.discard
          ? Text("无法使用", style: textStyle)
          : Text(_getPingTimeStr(climbWebsite), style: textStyle),
    ],
  );
}

String _getPingTimeStr(ClimbWebsite e) {
  if (e.pingStatus.pinging) {
    return "测试中...";
  }
  if (e.pingStatus.needPing) {
    return "未知";
  }
  if (e.pingStatus.connectable) {
    return "${e.pingStatus.time}ms";
  }
  return "超时";
}

_getPingStatusIcon(PingStatus pingStatus) {
  return Icon(Icons.circle, size: 12, color: pingStatus.color);
}
