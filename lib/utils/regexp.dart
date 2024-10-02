class RegexpUtil {
  static String? extractFirstEmoji(String text) {
    RegExp rx = RegExp(
        r'[\p{Extended_Pictographic}\u{1F3FB}-\u{1F3FF}\u{1F9B0}-\u{1F9B3}]',
        unicode: true);
    return rx.firstMatch(text)?[0];
  }

  static String? extractDate(String? text) {
    if (text == null) return null;
    return RegExp(r'\d{4}(-\d{0,2}){0,2}').firstMatch(text)?[0];
  }
}
