class NumberUtil {
  /// 填充前置0，默认宽度为2
  /// 示例：1→01，12→12
  static String fillPreZero(int num, {int width = 2}) {
    return num.toString().padLeft(width, '0');
  }
}
