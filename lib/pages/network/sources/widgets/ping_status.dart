import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/models/ping_result.dart';
import 'package:flutter_test_future/utils/theme_util.dart';

buildPingStatusRow(ClimbWebsite climbWebsite, {bool gridStyle = false}) {
  return Row(
    mainAxisAlignment:
        gridStyle ? MainAxisAlignment.center : MainAxisAlignment.start,
    children: [
      climbWebsite.discard
          ? _getPingStatusIcon(PingStatus())
          : _getPingStatusIcon(climbWebsite.pingStatus),
      const SizedBox(width: 4),
      climbWebsite.discard
          ? const Text("无法使用", textScaleFactor: ThemeUtil.tinyScaleFactor)
          : Text(_getPingTimeStr(climbWebsite),
              textScaleFactor: ThemeUtil.tinyScaleFactor),
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
