import 'package:flutter/material.dart';
import 'package:animetrace/models/climb_website.dart';
import 'package:animetrace/models/ping_result.dart';

buildPingStatusRow(BuildContext context, ClimbWebsite climbWebsite,
    {bool gridStyle = false}) {
  var textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.1);
  return Row(
    mainAxisAlignment:
        gridStyle ? MainAxisAlignment.center : MainAxisAlignment.start,
    children: [
      Icon(
        Icons.circle,
        size: 12,
        color: (climbWebsite.discard
                ? const PingStatus()
                : climbWebsite.pingStatus)
            .color,
      ),
      const SizedBox(width: 4),
      climbWebsite.discard
          ? Text("无法使用", style: textStyle)
          : Text(climbWebsite.pingStatus.label, style: textStyle),
    ],
  );
}
