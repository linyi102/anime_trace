import 'package:flutter_test_future/utils/sp_util.dart';

class TimeShowUtil {
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

  // 显示年月日时分
  static String getHumanReadableDateTimeStr(String time,
      {bool showTime = true, bool showDayOfWeek = false}) {
    if (time.isEmpty) return "";

    DateTime dateTime = DateTime.parse(time);
    String dateTimeStr = dateTime.toString();
    DateTime now = DateTime.now();
    //         0123456789      16
    // 参考时间：1969-07-20 20:18:04Z

    String yearStr = dateTimeStr.substring(0, 4);
    String monthStr = dateTimeStr.substring(5, 7);
    String dayStr = dateTimeStr.substring(8, 10);
    String hourAndMinuteStr = dateTimeStr.substring(11, 16);
    // 先得到年后面的月日时分
    String showTimeStr = "";
    // 同月，并且设置了显示昨天或今天
    if (showYesterdayAndToday && dateTime.month == now.month) {
      if (dateTime.day == now.day) {
        showTimeStr += "今天";
      } else if (now.day.toInt() - dateTime.day.toInt() == 1) {
        showTimeStr += "昨天";
      } else {
        // 同月但不是昨天和今天
        showTimeStr += "$monthStr-$dayStr";
      }
    } else {
      // 始终显示月日
      showTimeStr += "$monthStr-$dayStr";
    }
    // 如果允许，并且如果用户设置了显示精确时间，才会加上时分
    if (showTime && showPreciseTime) {
      showTimeStr += " $hourAndMinuteStr";
    }
    // 再添加年份
    if (dateTime.year == now.year) {
      // 如果是今年，且仍要显示年份。注意如果显示了今天或昨天，则不显示年份
      if (showCurYear && !showTimeStr.contains("天")) {
        showTimeStr = "$yearStr-$showTimeStr";
      } else {
        // 不显示今年
      }
    } else {
      // 不是今年，始终添加年份
      showTimeStr = "$yearStr-$showTimeStr";
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
      String weekdayStr;
      switch (dateTime.weekday) {
        case 1:
          weekdayStr = "一";
          break;
        case 2:
          weekdayStr = "二";
          break;
        case 3:
          weekdayStr = "三";
          break;
        case 4:
          weekdayStr = "四";
          break;
        case 5:
          weekdayStr = "五";
          break;
        case 6:
          weekdayStr = "六";
          break;
        case 7:
          weekdayStr = "日";
          break;
        default:
          weekdayStr = "";
      }
      showTimeStr += " 周$weekdayStr";
    }

    return showTimeStr;
  }
}
