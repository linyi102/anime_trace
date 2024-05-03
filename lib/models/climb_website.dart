import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/models/ping_result.dart';

class ClimbWebsite {
  int id;
  String name;
  String iconUrl;
  bool enable;
  String regexp; // 用于根据animeUrl获取对应网站
  String spkey; // shared_preferencens存储的key，用于获取是否开启
  PingStatus pingStatus;
  String comment; // 注释
  String desc; // 描述
  Climb climb; // 爬取工具
  bool discard; // 放弃使用
  bool supportImport; // 支持导入
  bool supportPlayVideo;

  ClimbWebsite({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.enable,
    required this.spkey,
    required this.pingStatus,
    required this.regexp,
    required this.climb,
    this.comment = "",
    this.desc = "",
    this.discard = false,
    this.supportImport = false,
    this.supportPlayVideo = false,
  });

  @override
  String toString() {
    return "[name=$name, enable=$enable]";
  }
}
