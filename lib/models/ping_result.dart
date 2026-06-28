import 'package:animetrace/values/values.dart';
import 'package:flutter/material.dart';

sealed class PingStatus {
  const factory PingStatus() = PingStatusUnknown;

  const factory PingStatus.pinging() = PingStatusPinging;

  const factory PingStatus.success(int time) = PingStatusSuccess;

  const factory PingStatus.timeout(int time) = PingStatusTimeout;
}

class PingStatusUnknown implements PingStatus {
  const PingStatusUnknown();

  @override
  String toString() => 'PingStatus[unknown]';
}

class PingStatusPinging implements PingStatus {
  const PingStatusPinging();

  @override
  String toString() => 'PingStatus[pinging]';
}

class PingStatusSuccess implements PingStatus {
  const PingStatusSuccess(this.time);

  final int time;

  @override
  String toString() => 'PingStatus[ok=true, time=$time]';
}

class PingStatusTimeout implements PingStatus {
  const PingStatusTimeout(this.time);

  final int time;

  @override
  String toString() => 'PingStatus[ok=false, time=$time]';
}

extension PingStatusExt on PingStatus {
  String get label => switch (this) {
        PingStatusPinging() => '测试中...',
        PingStatusUnknown() => '未知',
        PingStatusSuccess(:final time) => '${time}ms',
        PingStatusTimeout() => '超时',
      };

  Color get color => switch (this) {
        PingStatusUnknown() || PingStatusPinging() => Colors.grey,
        PingStatusSuccess() => AppTheme.connectableColor,
        PingStatusTimeout() => Colors.red,
      };
}
