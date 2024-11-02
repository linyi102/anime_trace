import 'package:flutter_test_future/utils/number_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:get_time_ago/get_time_ago.dart';

class TimeUtil {
  static final unRecordedDateTime = DateTime(0);

  static isUnRecordedDateTimeStr(String str) => str.startsWith('0000');

  /// 根据秒数转为时长字符串
  static String getReadableDuration(Duration duration) {
    String res = "";
    int hour = duration.inHours % 24;
    int min = duration.inMinutes % 60;
    int sec = duration.inSeconds % 60;

    if (duration.inHours > 0) res += "$hour:";
    res += "${NumberUtil.fillPreZero(min)}:${NumberUtil.fillPreZero(sec)}";

    return res;
  }

  static bool showPreciseTime = SPUtil.getBool("showPreciseTime",
      defaultValue: true); // 为true表示显示时间时，精确到时分
  static bool showYesterdayAndToday = SPUtil.getBool("showYesterdayAndToday",
      defaultValue: true); // 为true表示如果是昨天或今天，则以汉字表现出来
  static bool showCurYear = SPUtil.getBool("showCurYear",
      defaultValue: false); // 为false表示如果时间为今年，则不用显示出来

  static void turnShowPreciseTime() {
    showPreciseTime = !showPreciseTime;
    SPUtil.setBool("showPreciseTime", showPreciseTime);
  }

  static void turnShowYesterdayAndToday() {
    showYesterdayAndToday = !showYesterdayAndToday;
    SPUtil.setBool("showYesterdayAndToday", showYesterdayAndToday);
  }

  static void turnShowCurYear() {
    showCurYear = !showCurYear;
    SPUtil.setBool("showCurYear", showCurYear);
  }

  // 获取当前时间的字符串形式
  static String getDateTimeNowStr() {
    return DateTime.now().toString().substring(0, 19);
  }

  // 显示年月日时分
  static String getHumanReadableDateTimeStr(
    String time, {
    bool showTime = true,
    bool showDayOfWeek = false,
    String delimiter = "-",
    bool chineseDelimiter = false, // 如果为true，优先采用xxxx年xx月xx日，否则使用delimiter
    bool removeLeadingZero = false,
  }) {
    if (time.isEmpty) return "";
    DateTime? dateTime = DateTime.tryParse(time);
    if (dateTime == null) return "";
    if (dateTime == unRecordedDateTime) return "";

    String dateTimeStr = dateTime.toString();
    DateTime now = DateTime.now();
    //         0123456789      16
    // 参考时间：1969-07-20 20:18:04Z

    String yearStr = dateTimeStr.substring(0, 4);
    String monthStr = dateTimeStr.substring(5, 7);
    String dayStr = dateTimeStr.substring(8, 10);
    String hourAndMinuteStr = dateTimeStr.substring(11, 16);

    if (removeLeadingZero && monthStr.startsWith("0")) {
      monthStr = monthStr.substring(1, monthStr.length);
    }
    if (removeLeadingZero && dayStr.startsWith("0")) {
      dayStr = dayStr.substring(1, dayStr.length);
    }

    if (chineseDelimiter) {
      delimiter = "";
      yearStr += "年";
      monthStr += "月";
      dayStr += "日";
    }

    // 先得到年后面的月日时分
    String showTimeStr = "";
    // 同年同月，并且设置了显示昨天或今天
    if (showYesterdayAndToday &&
        dateTime.year == now.year &&
        dateTime.month == now.month) {
      if (dateTime.day == now.day) {
        showTimeStr += "今天";
      } else if (now.day.toInt() - dateTime.day.toInt() == 1) {
        showTimeStr += "昨天";
      } else {
        // 同月但不是昨天和今天
        showTimeStr += "$monthStr$delimiter$dayStr";
      }
    } else {
      // 始终显示月日
      showTimeStr += "$monthStr$delimiter$dayStr";
    }
    // 如果允许，并且如果用户设置了显示精确时间，才会加上时分
    if (showTime && showPreciseTime) {
      showTimeStr += " $hourAndMinuteStr";
    }
    // 再添加年份
    if (dateTime.year == now.year) {
      // 如果是今年，且仍要显示年份。注意如果显示了今天或昨天，则不显示年份
      if (showCurYear && !showTimeStr.contains("天")) {
        showTimeStr = "$yearStr$delimiter$showTimeStr";
      } else {
        // 不显示今年
      }
    } else {
      // 不是今年，始终添加年份
      showTimeStr = "$yearStr$delimiter$showTimeStr";
    }

    // if (dateTime.year != now.year) {
    //   // 如果要显示精确时间，则加上时分
    //   if (showTime && showPreciseTime) {
    //     return dateTimeStr.substring(0, 16);
    //   } else {
    //     return dateTimeStr.substring(0, 10);
    //   }
    // }
    //
    // String showTimeStr = "";
    // if (showCurYear) {
    //   // 如果设置了显示今年，不管在哪一年都要显示年1
    //   dateTimeStr.substring(0, 16);
    // } else {
    //   // 如果时间在今年，并且设置了不显示今年，则只显示月日
    //   showTimeStr = dateTimeStr.substring(5, 10);
    // }
    // // 同月，并且设置了显示昨天或今天
    // if (showYesterdayAndToday && dateTime.month == now.month) {
    //   if (dateTime.day == now.day) {
    //     showTimeStr = "今天";
    //   } else if (now.day.toInt() - dateTime.day.toInt() == 1) {
    //     showTimeStr = "昨天";
    //   }
    // }
    // // 如果允许，并且如果用户设置了显示精确时间，才会加上时分
    // if (showTime && showPreciseTime) {
    //   showTimeStr += " ${dateTimeStr.substring(11, 16)}";
    // }

    if (showDayOfWeek) {
      showTimeStr += " 周${getChineseWeekdayByNumber(dateTime.weekday)}";
    }

    return showTimeStr;
  }

  static String getChineseWeekdayByNumber(int weekday) {
    switch (weekday) {
      case 1:
        return "一";
      case 2:
        return "二";
      case 3:
        return "三";
      case 4:
        return "四";
      case 5:
        return "五";
      case 6:
        return "六";
      case 7:
        return "日";
      default:
        return "？";
    }
  }

  /// 传入格式：2023、2023-02、2023-02-13
  /// 输出格式：2023年、2023年02月、2023年02月13日
  static String getChineseDate(String date) {
    if (date.isEmpty) return '';

    // 传入2021-12-24 23:40:02.344074时，过滤掉空格以及后面的信息
    int space = date.indexOf(' ');
    if (space >= 0) {
      date = date.substring(0, space);
    }

    String res = "";
    List<String> numStrs = date.split("-");
    List<String> units = ["年", "月", "日"];

    for (int i = 0; i < numStrs.length; ++i) {
      if (i >= units.length) break;
      res += "${numStrs[i]}${units[i]}";
    }
    return res;
  }

  /// 和当前时间间隔
  static String getTimeAgo(
    DateTime dateTime, {
    String pattern = 'yyyy-MM-dd hh:mm:ss',
  }) {
    return GetTimeAgo.parse(
      dateTime,
      locale: 'zh',
      pattern: pattern,
    );
  }
}
