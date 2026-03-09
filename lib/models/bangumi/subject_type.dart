import 'package:get/get.dart';

enum BgmSubjectType {
  all('全部', 'all'),
  anime('动画', '2'),
  book('书籍', '1'),
  music('音乐', '3'),
  game('游戏', '4'),
  threeD('三次元', '6');

  final String label;
  final String value;
  const BgmSubjectType(this.label, this.value);

  static BgmSubjectType? fromValue(String value) {
    return BgmSubjectType.values
        .firstWhereOrNull((element) => element.value == value);
  }
}
