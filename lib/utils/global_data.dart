// List tags = ["拾", "途", "终", "搁", "弃"];
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/climb_website.dart';
import 'package:flutter_test_future/classes/filter.dart';
import 'package:flutter_test_future/utils/ping_result.dart';
import 'package:flutter_test_future/utils/sp_util.dart';

List<String> tags = [];
List<int> animeCntPerTag = []; // 各个标签下的动漫数量
List<List<Anime>> animesInTag = []; // 各个标签下的动漫列表
List<Anime> directory = []; // 目录动漫
Filter filter = Filter(); // 目录页中的过滤条件

List<ClimbWebstie> climbWebsites = [
  ClimbWebstie(
      name: "樱花动漫",
      iconAssetUrl: "assets/images/website/yhdm.png",
      baseUrl: "https://www.yhdmp.cc",
      keyword: "yhdm",
      spkey: "enableWebSiteYhdm",
      enable: SPUtil.getBool("enableWebSiteYhdm", defaultValue: true),
      pingStatus: PingStatus()),
  ClimbWebstie(
      name: "AGE 动漫",
      iconAssetUrl: "assets/images/website/agemys.jpg",
      baseUrl: "https://www.agemys.cc",
      keyword: "agemys",
      spkey: "enableWebSiteAgemys",
      enable: SPUtil.getBool("enableWebSiteAgemys", defaultValue: true),
      pingStatus: PingStatus()),
  ClimbWebstie(
      name: "OmoFun",
      iconAssetUrl: "assets/images/website/OmoFun.jpg",
      baseUrl: "https://omofun.tv",
      keyword: "omofun",
      spkey: "enableWebSiteOmofun",
      enable: SPUtil.getBool("enableWebSiteOmofun", defaultValue: true),
      pingStatus: PingStatus(),
      comment: "图片较大，流量慎用"),
];
