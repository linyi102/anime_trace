class Label {
  int id;
  String name;

  Label(this.id, this.name);

  factory Label.fromMap(Map<String, Object?> map) {
    return Label(
      map["id"] as int,
      map["name"] as String,
    );
  }

  // 生成无效的标签，用于查询不到时返回
  factory Label.noneLabel() {
    return Label(-1, "");
  }

  bool get isNone => id == -1 && name.isEmpty;
  bool get isValid => !isNone;

  @override
  String toString() {
    return 'Label{id: $id, name: $name}';
  }
}
