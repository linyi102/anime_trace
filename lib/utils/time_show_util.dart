class TimeShowUtil {
  // 显示年月日
  // 默认始终显示年，将-替换为/
  static String getShowDateStr(String time, {bool hideCurYear = false, bool isSlash = true}) {
    DateTime dateTime = DateTime.parse(time);
    String dateTimeStr = dateTime.toString();
    DateTime now = DateTime.now();
    String sep = isSlash ? "/" : "-";
    if (hideCurYear && now.year == dateTime.year) {
      return dateTimeStr.substring(5, 10).replaceAll("-", sep);
    }
    return dateTimeStr.substring(0, 10).replaceAll("-", sep);
  }

  // 显示年月日时分
  static String getShowDateTimeStr(String time) {
    DateTime dateTime = DateTime.parse(time);
    String dateTimeStr = dateTime.toString();
    DateTime now = DateTime.now();
    //         0123456789      16
    // 参考时间：1969-07-20 20:18:04Z
    // 年份不一样
    if (dateTime.year != now.year) {
      return dateTimeStr.substring(0, 16);
    }

    String showTimeStr = "";
    // 同年，显示月日
    showTimeStr = dateTimeStr.substring(5, 10);
    // 同月
    if (dateTime.month == now.month) {
      if (dateTime.day == now.day) {
        showTimeStr = "今天";
      } else if (now.day.toInt() - dateTime.day.toInt() == 1) {
        showTimeStr = "昨天";
      }
    }
    // 最后加上时分
    return "$showTimeStr ${dateTimeStr.substring(11, 16)}";
  }
}
