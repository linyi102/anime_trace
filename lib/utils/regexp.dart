class RegexpUtil {
  static bool isUrl(String input) {
    return input.startsWith(RegExp(r'https?://'));
  }
}
