import 'package:animetrace/dao/label_dao.dart';
import 'package:animetrace/utils/regexp.dart';

class Label {
  int id;
  String name;
  int order;

  Label(this.id, this.name, {this.order = -1});

  factory Label.fromMap(Map<String, Object?> map) => LabelDao.row2Bean(map);

  // 生成无效的标签，用于查询不到时返回
  factory Label.noneLabel() {
    return Label(-1, "");
  }

  bool get isNone => id == -1 && name.isEmpty;
  bool get isValid => !isNone;

  String? get emoji => getEmoji(name);

  String get nameWithoutEmoji => getNameWithoutEmoji(name);

  static String? getEmoji(String name) {
    return RegexpUtil.extractFirstEmoji(name);
  }

  static String getNameWithoutEmoji(String name) {
    final emoji = getEmoji(name);
    return emoji == null ? name : name.replaceFirst(emoji, '').trim();
  }

  @override
  String toString() {
    return 'Label{id: $id, name: $name}';
  }

  Label copyWith({
    int? id,
    String? name,
    int? order,
  }) {
    return Label(
      id ?? this.id,
      name ?? this.name,
      order: order ?? this.order,
    );
  }
}
