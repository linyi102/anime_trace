import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/ping_result.dart';

class ClimbWebstie {
  String name;
  String iconAssetUrl;
  bool enable;
  String
      keyword; // 网址中的关键字。比如根据baseUrl=https://www.agemys.cc/和https://www.agemys.com/，他们都含有agemys，则可以根据收藏的动漫的原网址来退出动漫源
  String spkey; // shared_preferencens存储的key，用于获取是否开启
  PingStatus pingStatus;
  String comment; // 注释
  String desc; // 描述
  Climb climb; // 爬取工具

  ClimbWebstie(
      {required this.name,
      required this.iconAssetUrl,
      required this.enable,
      required this.spkey,
      required this.pingStatus,
      required this.keyword,
      required this.climb,
      this.comment = "",
      this.desc = ""});

  @override
  String toString() {
    return "[name=$name, enable=$enable]";
  }
}
