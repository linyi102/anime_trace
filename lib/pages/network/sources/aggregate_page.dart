import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/components/website_logo.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/pages/network/sources/logic.dart';
import 'package:flutter_test_future/pages/network/sources/modules/today_anime_list.dart';
import 'package:flutter_test_future/pages/network/sources/modules/tools.dart';
import 'package:flutter_test_future/pages/network/sources/pages/source_detail_page.dart';
import 'package:flutter_test_future/pages/network/sources/pages/source_list_page.dart';
import 'package:flutter_test_future/utils/dio_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/widgets/setting_title.dart';
import 'package:get/get.dart';

import '../../../models/ping_result.dart';
import '../../../widgets/icon_text_button.dart';

/// 聚合页
class AggregatePage extends StatefulWidget {
  const AggregatePage({Key? key}) : super(key: key);

  @override
  State<AggregatePage> createState() => _AggregatePageState();
}

class _AggregatePageState extends State<AggregatePage> {
  bool showPingDetail = true; // true时ListTile显示副标题，并做出样式调整
  bool canClickPingButton = true; // 限制点击ping按钮(10s一次)。切换页面会重置(暂不打算改为全局变量)

  double get itemHeight => 100.0;
  double get itemWidth => 100.0;

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
    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
      },
      child: ListView(
        children: [
          _buildClimbWebsiteGridCard(),
          _buildTools(),
          _buildAnimesList()
        ],
      ),
    );
  }

  _buildTools() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle("工具"),
          const ToolsPage(),
        ],
      ),
    );
  }

  _buildAnimesList() {
    return Card(
      child: Column(
        children: [
          _buildCardTitle('今日开播'),
          logic.loadingAnimesNYearsAgoTodayBroadcast
              ? const Row(
                  children: [
                    SizedBox(width: 20),
                    LoadingWidget(),
                  ],
                )
              : logic.animesNYearsAgoTodayBroadcast.isEmpty
                  ? const ListTile(title: Text('无'))
                  : const TodayAnimeListPage(),
        ],
      ),
    );
  }

  _buildClimbWebsiteGridCard() {
    return Card(
      child: Column(
        children: [
          _buildCardTitle("搜索源", trailing: _buldMoreSourceButton()),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                    margin:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    onTap: () => _enterSourceDetail(climbWebsite),
                    icon: Stack(
                      children: [
                        WebSiteLogo(url: climbWebsite.iconUrl, size: 40),
                        _buildPingStatus(climbWebsite.pingStatus)
                      ],
                    ),
                    text: Text(
                      climbWebsite.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(height: 1.1, fontSize: 13),
                    ));
              }),
        ],
      ),
    );
  }

  _buildCardTitle(String title, {Widget? trailing}) {
    return SettingTitle(
      title: title,
      trailing: trailing,
    );
    // return ListTile(
    //   title: Text(title, style: const TextStyle(fontSize: 16)),
    //   trailing: trailing,
    // );
  }

  Positioned _buildPingStatus(PingStatus pingStatus) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        height: 12,
        width: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).appBarTheme.backgroundColor,
        ),
        child: Icon(Icons.circle, size: 10, color: pingStatus.color),
      ),
    );
  }

  InkWell _buldMoreSourceButton() {
    return InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SourceListPage()));
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "更多",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(height: 1.2),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 10,
                color: Theme.of(context).textTheme.bodySmall?.color,
              )
            ],
          ),
        ));
  }

  _enterSourceDetail(ClimbWebsite climbWebsite) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return SourceDetail(climbWebsite);
    }));
  }
}
