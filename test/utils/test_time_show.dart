import 'package:flutter_test_future/utils/time_util.dart';
import 'package:flutter_test_future/utils/log.dart';

main() {
  // 不是今年
  Log.info(TimeUtil.getHumanReadableDateTimeStr("1969-07-20 20:18:04"));
  // 同年
  Log.info(TimeUtil.getHumanReadableDateTimeStr("2022-02-04 10:43:04"));
  Log.info(TimeUtil.getHumanReadableDateTimeStr("2022-09-01 10:43:04"));
  // 今天
  Log.info(TimeUtil.getHumanReadableDateTimeStr("2022-09-04 10:43:04"));
  // 昨天
  Log.info(TimeUtil.getHumanReadableDateTimeStr("2022-09-03 10:43:04"));
}
