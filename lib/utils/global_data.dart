// List tags = ["拾", "途", "终", "搁", "弃"];
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/climb_website.dart';
import 'package:flutter_test_future/classes/filter.dart';
import 'package:flutter_test_future/utils/climb/climb_agemys.dart';
import 'package:flutter_test_future/utils/climb/climb_cycdm.dart';
import 'package:flutter_test_future/utils/climb/climb_omofun.dart';
import 'package:flutter_test_future/utils/climb/climb_yhdm.dart';
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
      keyword: "yhdm",
      spkey: "enableWebSiteYhdm",
      enable: SPUtil.getBool("enableWebSiteYhdm", defaultValue: true),
      pingStatus: PingStatus(),
      climb: ClimbYhdm(),
      desc: "樱花动漫(pan)——支持网盘下载的樱花动漫，动漫免费在线观看，免费下载，无需注册，更新及时，我们致力打造最好的樱花动漫站！"),
  ClimbWebstie(
      name: "AGE 动漫",
      iconAssetUrl: "assets/images/website/agemys.jpg",
      keyword: "agemys",
      spkey: "enableWebSiteAgemys",
      enable: SPUtil.getBool("enableWebSiteAgemys", defaultValue: true),
      pingStatus: PingStatus(),
      climb: ClimbAgemys(),
      desc: "AGE动漫专注于资源收集整理 海量的有效的高质量的动漫资源下载 动漫百度网盘下载"),
  ClimbWebstie(
      name: "OmoFun",
      iconAssetUrl: "assets/images/website/OmoFun.jpg",
      keyword: "omofun",
      spkey: "enableWebSiteOmofun",
      enable: SPUtil.getBool("enableWebSiteOmofun", defaultValue: true),
      pingStatus: PingStatus(),
      climb: ClimbOmofun(),
      comment: "图片较大，流量慎用",
      desc: "提供最新最快的动漫新番资讯和在线播放，开心看动漫，无圣骑、无暗牧"),
  ClimbWebstie(
      name: "次元城动漫",
      iconAssetUrl: "assets/images/website/cycdm.png",
      keyword: "cycacg", // 关键字用于根据某个动漫的详细网址来推出属于哪个动漫，因此应该是17skr
      spkey: "enableWebSiteCycdm",
      enable: SPUtil.getBool("enableWebSiteCycdm", defaultValue: false),
      pingStatus: PingStatus(),
      climb: ClimbCycdm(),
      desc: "高质量在线追番平台！"),
];
