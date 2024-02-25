import 'package:get/get.dart';

enum BangumiSearchCategory {
  all('全部', 'all'),
  anime('动画', '2'),
  book('书籍', '1'),
  music('音乐', '3'),
  game('游戏', '4'),
  threeD('三次元', '6');

  final String label;
  final String key;
  const BangumiSearchCategory(this.label, this.key);

  static BangumiSearchCategory? getCategoryByKey(String key) {
    return BangumiSearchCategory.values
        .firstWhereOrNull((element) => element.key == key);
  }
}
