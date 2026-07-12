import 'package:get/get.dart';

enum BgmSubjectType {
  all('全部', 'all', null),
  anime('动画', '2', 2),
  book('书籍', '1', 1),
  music('音乐', '3', 3),
  game('游戏', '4', 4),
  threeD('三次元', '6', 6);

  final String label;
  final String value;
  final int? intValue;
  const BgmSubjectType(this.label, this.value, this.intValue);

  static BgmSubjectType? fromValue(String value) {
    return BgmSubjectType.values
        .firstWhereOrNull((element) => element.value == value);
  }
}
