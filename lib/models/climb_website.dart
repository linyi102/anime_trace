import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/models/ping_result.dart';

class ClimbWebsite {
  String name;
  String iconUrl;
  bool enable;
  String
      keyword; // 网址中的关键字，用于数据库like(sqlite不支持正则，因此使用通配符)。比如根据baseUrl=https://www.agemys.cc/和https://www.agemys.com/，他们都含有agemys，则可以根据收藏的动漫的原网址来推出动漫源
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
    required this.name,
    required this.iconUrl,
    required this.enable,
    required this.spkey,
    required this.pingStatus,
    required this.keyword,
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
