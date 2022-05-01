// List tags = ["拾", "途", "终", "搁", "弃"];
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/climb_website.dart';
import 'package:flutter_test_future/classes/filter.dart';
import 'package:flutter_test_future/utils/sp_util.dart';

List<String> tags = [];
List<int> animeCntPerTag = []; // 各个标签下的动漫数量
List<List<Anime>> animesInTag = []; // 各个标签下的动漫列表
List<Anime> directory = []; // 目录动漫
Filter filter = Filter(); // 目录页中的过滤条件

List<ClimbWebStie> climbWebsites = [
  ClimbWebStie(
      name: "樱花动漫",
      baseUrl: "https://www.yhdmp.cc",
      spkey: "enableWebSiteYhdm",
      enable: SPUtil.getBool("enableWebSiteYhdm", defaultValue: true)),
  ClimbWebStie(
      name: "AGE 动漫",
      baseUrl: "https://www.agemys.com",
      spkey: "enableWebSiteAgemys",
      enable: SPUtil.getBool("enableWebSiteAgemys", defaultValue: true)),
  ClimbWebStie(
      name: "OmoFun",
      baseUrl: "https://omofun.tv",
      spkey: "enableWebSiteOmofun",
      enable: SPUtil.getBool("enableWebSiteOmofun", defaultValue: false)),
];
