// List tags = ["拾", "途", "终", "搁", "弃"];
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/utils/climb/climb_agemys.dart';
import 'package:flutter_test_future/utils/climb/climb_aimii.dart';
import 'package:flutter_test_future/utils/climb/climb_cycdm.dart';
import 'package:flutter_test_future/utils/climb/climb_douban.dart';
import 'package:flutter_test_future/utils/climb/climb_omofun.dart';
import 'package:flutter_test_future/utils/climb/climb_yhdm.dart';
import 'package:flutter_test_future/utils/ping_result.dart';
import 'package:flutter_test_future/utils/sp_util.dart';

List<String> tags = [];
List<int> animeCntPerTag = []; // 各个标签下的动漫数量
List<List<Anime>> animesInTag = []; // 各个标签下的动漫列表
List<Anime> directory = []; // 目录动漫
AnimeFilter filter = AnimeFilter(); // 目录页中的过滤条件

List<ClimbWebsite> climbWebsites = [
  ClimbWebsite(
      name: "樱花动漫",
      iconUrl: "https://www.yhdmp.cc/yxsf/yh_pic/favicon.ico",
      keyword: "yhdm",
      spkey: "enableWebSiteYhdm",
      enable: SPUtil.getBool("enableWebSiteYhdm", defaultValue: true),
      pingStatus: PingStatus(),
      climb: ClimbYhdm(),
      desc: "樱花动漫(pan)——支持网盘下载的樱花动漫，动漫免费在线观看，免费下载，无需注册，更新及时，我们致力打造最好的樱花动漫站！"),
  ClimbWebsite(
      name: "AGE动漫",
      iconUrl: "assets/images/website/agemys.jpg",
      keyword: "agemys",
      spkey: "enableWebSiteAgemys",
      enable: SPUtil.getBool("enableWebSiteAgemys", defaultValue: true),
      pingStatus: PingStatus(),
      climb: ClimbAgemys(),
      desc: "AGE动漫专注于资源收集整理 海量的有效的高质量的动漫资源下载 动漫百度网盘下载"),
  ClimbWebsite(
      name: "OmoFun",
      iconUrl: "assets/images/website/OmoFun.jpg",
      keyword: "omofun",
      spkey: "enableWebSiteOmofun",
      enable: false,
      discard: true,
      pingStatus: PingStatus(),
      climb: ClimbOmofun(),
      comment: "图片较大，流量慎用",
      desc: "提供最新最快的动漫新番资讯和在线播放，开心看动漫，无圣骑、无暗牧"),
  ClimbWebsite(
      name: "次元城动漫",
      iconUrl: "https://www.cycdm01.top/upload/mxprocms/20220825-1/94f5bbad3547f250ed2ed3684d11e19d.png",
      keyword: "cyc",
      spkey: "enableWebSiteCycdm",
      enable: SPUtil.getBool("enableWebSiteCycdm", defaultValue: false),
      pingStatus: PingStatus(),
      climb: ClimbCycdm(),
      desc: "高质量在线追番平台！"),
  ClimbWebsite(
      name: "艾米动漫",
      iconUrl: "https://img.gejiba.com/images/f1f102fc413011625bd2a610cac6c83b.png",
      keyword: "aimi",
      spkey: "enableWebSiteAimi",
      enable: SPUtil.getBool("enableWebSiteAimi", defaultValue: false),
      pingStatus: PingStatus(),
      climb: ClimbAimi(),
      desc: "艾米动漫致力于收集动漫资源，为广大网友提供各种好番而生。"),
  ClimbWebsite(
      name: "豆瓣",
      iconUrl: "https://www.douban.com/favicon.ico",
      enable: SPUtil.getBool("enableWebSiteDouban", defaultValue: false),
      spkey: "enableWebSiteDouban",
      pingStatus: PingStatus(),
      keyword: "douban",
      climb: ClimbDouban(),
  )
];
