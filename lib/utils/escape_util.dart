class EscapeUtil {
  static String escapeStr(String str) {
    return str.replaceAll("'", "''"); // 将'替换为''，进行转义，否则会在插入时误认为'为边界
  }

  static String restoreEscapeStr(String str) {
    return str.replaceAll("''", "'");
  }
}
