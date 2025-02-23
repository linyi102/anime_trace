import 'package:animetrace/models/anime.dart';

class Series {
  int id;
  String name;
  String desc;
  String coverUrl;
  String createTime;
  String updateTime;

  List<Anime> animes = [];

  Series(
    this.id,
    this.name, {
    this.desc = '',
    this.coverUrl = '',
    this.createTime = '',
    this.updateTime = '',
  });

  factory Series.fromMap(Map<String, Object?> map) {
    return Series(
      map["id"] as int,
      map["name"] as String,
      desc: map["desc"] as String,
      coverUrl: map["cover_url"] as String,
      createTime: map["create_time"] as String,
      updateTime: map["update_time"] as String,
    );
  }

  // 生成无效的系列，用于查询不到时返回
  factory Series.noneLabel() {
    return Series(-1, "");
  }

  bool get isNone => id == -1 && name.isEmpty;
  bool get isValid => !isNone;

  @override
  String toString() {
    return 'Series(id: $id, name: $name, desc: $desc, coverUrl: $coverUrl, createTime: $createTime, updateTime: $updateTime, animes.length: ${animes.length})';
  }
}
