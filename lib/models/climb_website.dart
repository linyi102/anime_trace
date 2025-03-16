import 'package:animetrace/utils/climb/climb.dart';
import 'package:animetrace/models/ping_result.dart';
import 'package:animetrace/utils/sp_util.dart';

class ClimbWebsite {
  int id;
  String name;
  String iconUrl;
  bool enable = false;
  String regexp; // 用于根据animeUrl获取对应网站
  String spkey; // shared_preferencens存储的key，用于获取是否开启
  PingStatus pingStatus = PingStatus();
  String comment; // 注释
  String desc; // 描述
  Climb climb; // 爬取工具
  bool discard; // 放弃使用
  bool supportImport; // 支持导入
  bool supportPlayVideo;

  ClimbWebsite({
    bool defaultEnable = false,
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.spkey,
    required this.regexp,
    required this.climb,
    this.comment = "",
    this.desc = "",
    this.discard = false,
    this.supportImport = false,
    this.supportPlayVideo = false,
  }) {
    enable = SPUtil.getBool(spkey, defaultValue: defaultEnable);
  }

  @override
  String toString() {
    return "[name=$name, enable=$enable]";
  }
}
