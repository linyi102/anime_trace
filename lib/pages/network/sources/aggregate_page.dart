import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_image.dart';
import 'package:flutter_test_future/components/website_logo.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/models/fav_website.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/pages/network/sources/logic.dart';
import 'package:flutter_test_future/pages/network/sources/pages/dedup/dedup_page.dart';
import 'package:flutter_test_future/pages/network/sources/pages/source_detail_page.dart';
import 'package:flutter_test_future/pages/network/sources/pages/source_list_page.dart';
import 'package:flutter_test_future/pages/network/sources/pages/trace/view.dart';
import 'package:flutter_test_future/pages/network/sources/widgets/ping_status.dart';
import 'package:flutter_test_future/utils/dio_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/values/theme.dart';
import 'package:get/get.dart';

import '../../../components/anime_list_cover.dart';
import '../../../models/anime.dart';

/// 聚合页
class AggregatePage extends StatefulWidget {
  const AggregatePage({Key? key}) : super(key: key);

  @override
  State<AggregatePage> createState() => _AggregatePageState();
}

class _AggregatePageState extends State<AggregatePage> {
  bool showPingDetail = true; // true时ListTile显示副标题，并做出样式调整
  bool canClickPingButton = true; // 限制点击ping按钮(10s一次)。切换页面会重置(暂不打算改为全局变量)

  final favWebsite = FavWebsite(
      url: "https://bgmlist.com/",
      // icoUrl: "https://bgmlist.com/public/favicons/apple-touch-icon.png",
      icoUrl: "assets/images/website/fzff.png",
      name: "番组放送");

  double get iconSize => 40.0;
  double get itemHeight => 100.0;
  double get itemWidth => 120.0;

  List<ClimbWebsite> usableWebsites = [];

  AggregateLogic logic = Get.put(AggregateLogic());

  @override
  void initState() {
    super.initState();

    // 网格只显示可用的搜索源
    for (var website in climbWebsites) {
      if (!website.discard) usableWebsites.add(website);
    }

    // 只要有一个needPing为false，则说明都ping过了或者正在ping，此时不需要再ping所有
    bool needPingAll = true;
    for (var website in climbWebsites) {
      if (website.pingStatus.needPing == false) {
        needPingAll = false;
      }
    }
    if (needPingAll) {
      _pingAllWebsites();
    }
  }

  void _refresh() {
    for (var website in climbWebsites) {
      website.pingStatus.needPing = true;
    }
    _pingAllWebsites();

    logic.loadAnimesNYearsAgoTodayBroadcast();
  }

  void _pingAllWebsites() {
    if (!canClickPingButton) {
      ToastUtil.showText("测试间隔为10s");
      return;
    }

    canClickPingButton = false;
    Future.delayed(const Duration(seconds: 10))
        .then((value) => canClickPingButton = true);

    for (var website in climbWebsites) {
      if (!website.discard && website.pingStatus.needPing) {
        website.pingStatus.connectable = false; // 表示不能连接(ping时显示灰色)
        website.pingStatus.pinging = true; // 表示正在ping
      }
    }
    setState(() {});
    for (var website in climbWebsites) {
      if (!website.discard && website.pingStatus.needPing) {
        DioUtil.ping(website.climb.baseUrl).then((value) {
          website.pingStatus = value;
          if (mounted) {
            setState(() {});
          }

          Log.info("${website.name}:pingStatus=${website.pingStatus}");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _refresh();
        },
        child: ListView(
          children: [
            _buildClimbWebsiteGridCard(),
            // _buildClimbWebsiteListViewCard(),
            _buildTools(),
            // FavWebsiteListPage()
            _buildAnimesList()
          ],
        ),
      ),
    );
  }

  _buildAnimesList() {
    return GetBuilder(
      init: logic,
      builder: (_) => Card(
        child: Column(
          children: [
            _buildCardTitle('今日开播'),
            // if (logic.animesNYearsAgoTodayBroadcast.isEmpty) const Text('暂无。'),
            _buildAnimesColumn(),
            // _buildAnimesRow()
          ],
        ),
      ),
    );
  }

  Container _buildAnimesRow() {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: logic.animesNYearsAgoTodayBroadcast
            .map((anime) => Container(
                  width: MediaQuery.of(context).size.width / 3.5,
                  margin: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () {},
                    child: Column(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 3.5,
                          child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.imgRadius),
                              child: CommonImage(anime.animeCoverUrl)),
                        ),
                        Text(anime.animeName,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                          _getDiffYear(anime),
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  _buildAnimesColumn() {
    return Column(
      children: [
        for (var anime in logic.animesNYearsAgoTodayBroadcast)
          ListTile(
            title: Text(anime.animeName, overflow: TextOverflow.ellipsis),
            subtitle: Text(_getDiffYear(anime)),
            leading: AnimeListCover(anime, showReviewNumber: false),
            onTap: () async {
              Anime value = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnimeDetailPage(anime),
                  ));
              anime.animeName = value.animeName;
              anime.animeCoverUrl = value.animeCoverUrl;
              logic.update();
            },
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  String _getDiffYear(Anime anime) {
    var year = DateTime.parse(anime.premiereTime).year;
    var diff = DateTime.now().year - year;
    String text = '';
    if (diff == 0) text = '今天';
    text = diff == 0 ? '今天' : '$diff年前的今天';
    return text;
  }

  _buildCardTitle(String title, {Widget? trailing}) {
    return ListTile(
      dense: true,
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: trailing,
    );
  }

  _buildClimbWebsiteGridCard() {
    return Card(
      child: Column(
        children: [
          _buildCardTitle("搜索源",
              trailing: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const SourceListPage()));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      "查看全部",
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ))),
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                mainAxisExtent: itemHeight, // 格子高度
                maxCrossAxisExtent: itemWidth, // 格子最大宽度
              ),
              itemCount: usableWebsites.length,
              itemBuilder: (context, index) {
                ClimbWebsite climbWebsite = usableWebsites[index];

                return IconTextButton(
                    iconSize: 40,
                    itemHeight: itemHeight,
                    itemWidth: itemWidth,
                    onTap: () => _enterSourceDetail(climbWebsite),
                    icon:
                        WebSiteLogo(url: climbWebsite.iconUrl, size: iconSize),
                    text: Column(
                      children: [
                        Text(
                          climbWebsite.name,
                          overflow: TextOverflow.ellipsis,
                          textScaleFactor: 0.9,
                          style: const TextStyle(height: 1.1),
                        ),
                        const SizedBox(height: 5),
                        buildPingStatusRow(context, climbWebsite,
                            gridStyle: true),
                      ],
                    ));
              }),
        ],
      ),
    );
  }

  _enterSourceDetail(ClimbWebsite climbWebsite) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return SourceDetail(climbWebsite);
    }));
  }

  _buildTools() {
    return Card(
      child: Column(
        children: [
          _buildCardTitle("工具"),
          // _buildToolsListView(),
          _buildToolsGridView(),
        ],
      ),
    );
  }

  SingleChildScrollView _buildToolsListView() {
    return SingleChildScrollView(
      child: Column(
        children: const [
          ListTile(
            // leading: WebSiteLogo(url: favWebsite.icoUrl, size: iconSize),
            leading: Icon(Icons.calendar_month),
            title: Text('番组放送'),
          ),
          ListTile(
            leading: Icon(Icons.filter_alt),
            title: Text('动漫去重'),
          ),
          ListTile(
            leading: Icon(Icons.timeline),
            title: Text('历史回顾'),
          ),
        ],
      ),
    );
  }

  GridView _buildToolsGridView() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        mainAxisExtent: 90, // 格子高度
        maxCrossAxisExtent: itemWidth, // 格子最大宽度
      ),
      children: [
        IconTextButton(
          iconSize: iconSize,
          icon: WebSiteLogo(url: favWebsite.icoUrl, size: iconSize),
          // icon: Container(
          //     decoration: const BoxDecoration(
          //         color: Color.fromRGBO(19, 189, 157, 1),
          //         shape: BoxShape.circle),
          //     child: const Center(
          //         child: Text("番",
          //             style: TextStyle(color: Colors.white, fontSize: 20)))),
          text: const Text("番组放送", textScaleFactor: 0.9),
          onTap: () =>
              LaunchUrlUtil.launch(context: context, uriStr: favWebsite.url),
        ),
        // IconTextButton(
        //     iconSize: iconSize,
        //     icon: Container(
        //         decoration: const BoxDecoration(
        //           // color: Theme.of(context).primaryColor,
        //           color: Color.fromRGBO(55, 197, 254, 1),
        //           shape: BoxShape.circle,
        //         ),
        //         child: const Icon(Icons.auto_fix_high_rounded,
        //             size: 18, color: Colors.white)),
        //     text: const Text("封面修复", textScaleFactor: 0.9),
        //     onTap: () => Navigator.of(context).push(MaterialPageRoute(
        //         builder: (context) => const LapseCoverAnimesPage()))),
        IconTextButton(
            iconSize: iconSize,
            // icon: const Icon(Icons.filter_alt),
            icon: Container(
                decoration: const BoxDecoration(
                  // color: Theme.of(context).primaryColor,
                  color: Color.fromRGBO(255, 199, 87, 1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.filter_alt,
                    size: 24, color: Colors.white)),
            text: const Text("动漫去重", textScaleFactor: 0.9),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DedupPage()))),
        IconTextButton(
            iconSize: iconSize,
            // icon: const Icon(Icons.timeline),
            icon: Container(
                decoration: const BoxDecoration(
                  // color: Theme.of(context).primaryColor,
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.history, size: 24, color: Colors.white)),
            text: const Text("历史回顾", textScaleFactor: 0.9),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TracePage()))),
        // IconTextButton(
        //     icon: Icon(Icons.auto_fix_high, size: iconSize),
        //     text: const Text("更新", textScaleFactor: 0.9),
        //     onTap: () => null),
        // IconTextButton(
        //     icon: Icon(Icons.date_range_rounded, size: iconSize),
        //     text: const Text("时间表", textScaleFactor: 0.9),
        //     onTap: () => null),
        // IconTextButton(
        //     icon: Icon(Icons.auto_fix_high, size: iconSize),
        //     text: const Text("目录", textScaleFactor: 0.9),
        //     onTap: () => null),
      ],
    );
  }
}

class IconTextButton extends StatelessWidget {
  const IconTextButton(
      {required this.icon,
      required this.text,
      this.onTap,
      this.itemHeight = 80,
      this.itemWidth = 80,
      this.iconSize = 30,
      super.key});

  final Widget icon;
  final Widget text;
  final void Function()? onTap;
  final double itemHeight;
  final double itemWidth;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        width: itemWidth,
        height: itemHeight,
        child: Column(
          children: [
            SizedBox(height: iconSize, width: iconSize, child: icon),
            const SizedBox(height: 5),
            text
          ],
        ),
      ),
    );
  }
}
