import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/utils/climb/climb_agemys.dart';
import 'package:flutter_test_future/utils/climb/climb_aimii.dart';
import 'package:flutter_test_future/utils/climb/climb_bangumi.dart';
import 'package:flutter_test_future/utils/climb/climb_cycdm.dart';
import 'package:flutter_test_future/utils/climb/climb_douban.dart';
import 'package:flutter_test_future/utils/climb/climb_omofun.dart';
import 'package:flutter_test_future/utils/climb/climb_qdm.dart';
import 'package:flutter_test_future/utils/climb/climb_quqi.dart';
import 'package:flutter_test_future/utils/climb/climb_yhdm.dart';
import 'package:flutter_test_future/models/ping_result.dart';
import 'package:flutter_test_future/utils/sp_util.dart';

List<Anime> directory = []; // 目录动漫
AnimeFilter filter = AnimeFilter(); // 目录页中的过滤条件

List<ClimbWebsite> climbWebsites = [
  yhdmClimbWebsite,
  ageClimbWebsite,
  cycClimbWebsite,
  doubanClimbWebsite,
  quClimbWebsite,
  quqiClimbWebsite,
  bangumiClimbWebsite,
  omofunClimbWebsite,
  aimiWebsite,
];

final yhdmClimbWebsite = ClimbWebsite(
    name: "樱花动漫",
    // iconUrl: "https://www.yhdmp.cc/yxsf/yh_pic/favicon.ico",
    iconUrl: "assets/images/website/yhdm.ico",
    keyword: "%yh%dm%", // 匹配yhdm和yhpdm
    regexp: "yhp?dm",
    spkey: "enableWebSiteYhdm",
    enable: SPUtil.getBool("enableWebSiteYhdm", defaultValue: true),
    pingStatus: PingStatus(),
    climb: ClimbYhdm(),
    desc: "樱花动漫(pan)——支持网盘下载的樱花动漫，动漫免费在线观看，免费下载，无需注册，更新及时，我们致力打造最好的樱花动漫站！");

final ageClimbWebsite = ClimbWebsite(
    name: "AGE动漫",
    iconUrl: "assets/images/website/agemys.jpg",
    keyword: "%age%",
    regexp: "age",
    spkey: "enableWebSiteAgemys",
    enable: SPUtil.getBool("enableWebSiteAgemys", defaultValue: true),
    pingStatus: PingStatus(),
    climb: ClimbAgemys(),
    desc: "AGE动漫专注于资源收集整理 海量的有效的高质量的动漫资源下载 动漫百度网盘下载");

final cycClimbWebsite = ClimbWebsite(
    name: "次元城动漫",
    iconUrl: "assets/images/website/cyc.png",
    keyword: "%cyc%",
    regexp: "cyc",
    spkey: "enableWebSiteCycdm",
    enable: SPUtil.getBool("enableWebSiteCycdm", defaultValue: false),
    pingStatus: PingStatus(),
    climb: ClimbCycdm(),
    supportPlayVideo: true,
    desc: "高质量在线追番平台！");

final doubanClimbWebsite = ClimbWebsite(
  name: "豆瓣",
  // iconUrl: "https://www.douban.com/favicon.ico",
  iconUrl: "assets/images/website/douban.ico",
  enable: SPUtil.getBool("enableWebSiteDouban", defaultValue: false),
  spkey: "enableWebSiteDouban",
  pingStatus: PingStatus(),
  keyword: "%douban%",
  regexp: "douban",
  climb: ClimbDouban(),
  supportImport: true,
);

final quClimbWebsite = ClimbWebsite(
    name: "趣动漫",
    iconUrl: "assets/images/website/qdm.png",
    enable: SPUtil.getBool("enableWebSiteQdm", defaultValue: false),
    spkey: "enableWebSiteQdm",
    pingStatus: PingStatus(),
    keyword: "%qdm%",
    regexp: "qdm",
    climb: ClimbQdm(),
    desc:
        "趣动漫致力为所有动漫迷们提供最好看的动漫、最新最快的高清动画下载及全集资源，观看完全免费、无须注册、高速播放、更新及时的专业在线动漫站。");

final quqiClimbWebsite = ClimbWebsite(
    name: "曲奇动漫",
    iconUrl: "assets/images/website/quqi.ico",
    keyword: "%quqi%",
    regexp: "quqi",
    spkey: "enableWebSiteQuqi",
    enable: SPUtil.getBool("enableWebSiteQuqi", defaultValue: false),
    pingStatus: PingStatus(),
    climb: ClimbQuqi(),
    desc:
        "曲奇动漫是由民间动漫爱好者创立，仅供学习交流使用。曲奇动漫致力于精品动漫资源收集整理，动漫免费在线观看、免费下载、新番动漫同步连载，动漫资讯同步更新，——欢迎访问曲奇动漫。");

final bangumiClimbWebsite = ClimbWebsite(
    name: "Bangumi",
    iconUrl: "assets/images/website/bangumi.png",
    keyword: "%bangumi.tv%",
    regexp: "bangumi\\.tv", // 因为次元城的动漫详细页链接包含bangumi，所以要添加.tv
    spkey: "enableWebSiteBangumi",
    enable: SPUtil.getBool("enableWebSiteBangumi", defaultValue: false),
    pingStatus: PingStatus(),
    climb: ClimbBangumi(),
    supportImport: true,
    desc: "专注于动漫、音乐、游戏领域，帮助你分享、发现与结识同好的ACG网络");

// 无法使用
final omofunClimbWebsite = ClimbWebsite(
    name: "OmoFun",
    iconUrl: "assets/images/website/omofun.jpg",
    keyword: "%omofun%",
    regexp: "omofun",
    spkey: "enableWebSiteOmofun",
    enable: false,
    discard: true,
    pingStatus: PingStatus(),
    climb: ClimbOmofun(),
    comment: "图片较大，流量慎用",
    desc: "提供最新最快的动漫新番资讯和在线播放，开心看动漫，无圣骑、无暗牧");

final aimiWebsite = ClimbWebsite(
    name: "艾米动漫",
    iconUrl: "assets/images/website/aimi.jpg",
    keyword: "%aimi%",
    regexp: "aimi",
    discard: true,
    spkey: "enableWebSiteAimi",
    enable: SPUtil.getBool("enableWebSiteAimi", defaultValue: false),
    pingStatus: PingStatus(),
    climb: ClimbAimi(),
    desc: "艾米动漫致力于收集动漫资源，为广大网友提供各种好番而生。");
