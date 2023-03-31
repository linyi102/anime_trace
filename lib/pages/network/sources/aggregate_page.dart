import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/website_logo.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/models/fav_website.dart';
import 'package:flutter_test_future/pages/network/sources/lapse_cover_fix/lapse_cover_animes_page.dart';
import 'package:flutter_test_future/pages/network/sources/source_detail_page.dart';
import 'package:flutter_test_future/pages/network/sources/source_list_page.dart';
import 'package:flutter_test_future/pages/network/sources/widgets/ping_status.dart';
import 'package:flutter_test_future/utils/dio_package.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_test_future/utils/log.dart';

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
      icoUrl: "https://bgmlist.com/public/favicons/apple-touch-icon.png",
      name: "番组放送");

  double iconSize = 30.0;
  double itemHeight = 100.0;
  double itemWidth = 120.0;

  List<ClimbWebsite> usableWebsites = [];

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
  }

  void _pingAllWebsites() {
    if (!canClickPingButton) {
      showToast("测试间隔为10s");
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
        DioPackage.ping(website.climb.baseUrl).then((value) {
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
            _buildTools()
            // FavWebsiteListPage()
          ],
        ),
      ),
    );
  }

  _buildCardTitle(String title, {Widget? trailing}) {
    return ListTile(
      title: Text(
        title,
        textScaleFactor: 1.1,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
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
                      textScaleFactor: 0.9,
                      style: TextStyle(color: ThemeUtil.getCommentColor()),
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
                        Text(climbWebsite.name,
                            overflow: TextOverflow.ellipsis,
                            textScaleFactor: 0.9),
                        buildPingStatusRow(climbWebsite, gridStyle: true),
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
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              mainAxisExtent: 80, // 格子高度
              maxCrossAxisExtent: itemWidth, // 格子最大宽度
            ),
            children: [
              IconTextButton(
                iconSize: iconSize,
                icon: WebSiteLogo(url: favWebsite.icoUrl, size: iconSize),
                text: const Text("番组放送", textScaleFactor: 0.9),
                onTap: () => LaunchUrlUtil.launch(
                    context: context, uriStr: favWebsite.url),
              ),
              IconTextButton(
                  iconSize: iconSize,
                  icon: Icon(Icons.auto_fix_high, size: iconSize),
                  text: const Text("封面修复", textScaleFactor: 0.9),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const LapseCoverAnimesPage()))),
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
          ),
        ],
      ),
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
