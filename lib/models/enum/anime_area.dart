import 'package:get/get_utils/get_utils.dart';

enum AnimeArea {
  unknown('未知'),
  japan('日本'),
  china('中国'),
  western('欧美');

  final String label;

  const AnimeArea(this.label);

  static AnimeArea parse(String text) {
    if (text.contains(RegExp(r'大陆|台湾|香港|澳门'))) {
      return AnimeArea.china;
    }
    return AnimeArea.values.firstWhereOrNull((e) => text.contains(e.label)) ??
        AnimeArea.unknown;
  }
}
