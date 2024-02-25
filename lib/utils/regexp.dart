class RegexpUtil {
  static String? extractFirstEmoji(String text) {
    RegExp rx = RegExp(
        r'[\p{Extended_Pictographic}\u{1F3FB}-\u{1F3FF}\u{1F9B0}-\u{1F9B3}]',
        unicode: true);
    return rx.firstMatch(text)?[0];
  }
}
