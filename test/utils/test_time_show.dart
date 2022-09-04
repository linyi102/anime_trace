import 'package:flutter/cupertino.dart';
import 'package:flutter_test_future/utils/time_show_util.dart';

main() {
  // 不是今年
  debugPrint(TimeShowUtil.getShowDateTimeStr("1969-07-20 20:18:04"));
  // 同年
  debugPrint(TimeShowUtil.getShowDateTimeStr("2022-02-04 10:43:04"));
  debugPrint(TimeShowUtil.getShowDateTimeStr("2022-09-01 10:43:04"));
  // 今天
  debugPrint(TimeShowUtil.getShowDateTimeStr("2022-09-04 10:43:04"));
  // 昨天
  debugPrint(TimeShowUtil.getShowDateTimeStr("2022-09-03 10:43:04"));
}