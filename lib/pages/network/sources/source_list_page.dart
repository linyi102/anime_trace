import 'package:expand_widget/expand_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_app_bar.dart';

import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/pages/network/sources/source_detail_page.dart';
import 'package:flutter_test_future/responsive.dart';
import 'package:flutter_test_future/utils/dio_package.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/models/ping_result.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../../../models/fav_website.dart';
import '../../../utils/launch_uri_util.dart';
import '../../../components/website_logo.dart';
import 'lapse_cover_fix/lapse_cover_animes_page.dart';

class SourceListPage extends StatefulWidget {
  const SourceListPage({Key? key}) : super(key: key);

  @override
  State<SourceListPage> createState() => _SourceListPageState();
}

class _SourceListPageState extends State<SourceListPage> {
  bool showPingDetail = true; // true时ListTile显示副标题，并做出样式调整
  bool canClickPingButton = true; // 限制点击ping按钮(10s一次)。切换页面会重置(暂不打算改为全局变量)

  final favWebsite = FavWebsite(
      url: "https://bgmlist.com/",
      icoUrl: "https://bgmlist.com/public/favicons/apple-touch-icon.png",
      name: "番组放送");

  @override
  void initState() {
    super.initState();

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
        // 使用ListView，而非SingleChildScrollView>Column，否则无法下拉刷新
        child: ListView(
          children: [
            // Responsive.isMobile(context)
            //     ? _buildClimbWebsiteListView()
            //     : _buildClimbWebsiteGridView(),

            // _buildClimbWebsiteGridCard(),

            _buildClimbWebsiteListViewCard(),
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
        // textScaleFactor: 1.2,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: trailing,
    );
  }

  _buildTools() {
    return Card(
      child: Column(
        children: [
          _buildCardTitle("工具"),
          Row(
            children: [
              MaterialButton(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                onPressed: () => LaunchUrlUtil.launch(
                    context: context, uriStr: favWebsite.url),
                child: Column(
                  children: [
                    WebSiteLogo(url: favWebsite.icoUrl, size: 24),
                    const SizedBox(height: 5),
                    const Text("番组放送", textScaleFactor: 0.9)
                  ],
                ),
              ),
              MaterialButton(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const LapseCoverAnimesPage()));
                },
                child: Column(
                  children: const [
                    Icon(Icons.auto_fix_high),
                    SizedBox(height: 5),
                    Text("修复封面", textScaleFactor: 0.9)
                  ],
                ),
              )
            ],
          ),

          // ListTile(
          //   title: Text.rich(TextSpan(children: [
          //     TextSpan(text: favWebsite.name),
          //     // WidgetSpan(child: Text(favWebsite.name + "")),
          //     // const WidgetSpan(child: Icon(Icons.open_in_new, size: 18)),
          //     // WidgetSpan(
          //     //     child: buildWebSiteIcon(
          //     //         url: favWebsite.icoUrl, size: 20)),
          //   ])),
          //   leading: WebSiteLogo(url: favWebsite.icoUrl, size: 24),
          //   onTap: () =>
          //       LaunchUrlUtil.launch(context: context, uriStr: favWebsite.url),
          // ),
          // ListTile(
          //   leading: const Icon(Icons.auto_fix_high),
          //   title: const Text("修复失效网络封面"),
          //   onTap: () {
          //     Navigator.of(context).push(MaterialPageRoute(
          //         builder: (context) => const LapseCoverAnimesPage()));
          //   },
          // ),

          // ListTile(
          //   title: const Text("查看自定义动漫"),
          //   onTap: () {
          //     Navigator.of(context).push(MaterialPageRoute(
          //         builder: (context) => const LapseCoverAnimesPage()));
          //   },
          // ),
        ],
      ),
    );
  }

  Container _buildClimbWebsiteGridCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      // 设置卡片颜色
      // decoration: BoxDecoration(
      //     color: ThemeUtil.getCardColor(),
      //     borderRadius: BorderRadius.circular(5)),
      child: GridView.builder(
          // 解决报错问题
          shrinkWrap: true,
          //解决不滚动问题
          physics: const NeverScrollableScrollPhysics(),
          // 网格内边距
          padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            mainAxisExtent: 100, // 格子高度
            maxCrossAxisExtent: 100, // 格子宽度
          ),
          itemCount: climbWebsites.length,
          itemBuilder: (context, index) {
            ClimbWebsite climbWebsite = climbWebsites[index];
            return MaterialButton(
              onPressed: () => enterSourceDetail(climbWebsite),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    // 圆形边界和网站图标的距离
                    padding: const EdgeInsets.all(5),
                    child: WebSiteLogo(url: climbWebsite.iconUrl, size: 30),
                    decoration: BoxDecoration(
                        border: Border.all(
                            width: 1, color: climbWebsite.pingStatus.color),
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  Text(
                    climbWebsite.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  _buildSwitchButton(climbWebsite)
                ],
              ),
            );
          }),
    );
  }

  GridView _buildClimbWebsiteGridView() {
    // 获取还没有失效的搜索源列表
    List<ClimbWebsite> fineClimbWebsites = [];
    for (var e in climbWebsites) {
      if (!e.discard) {
        fineClimbWebsites.add(e);
      }
    }

    return GridView.builder(
        // 解决报错问题
        shrinkWrap: true,
        // 解决不滚动问题
        physics: const NeverScrollableScrollPhysics(),
        // 使用WithMaxCrossAxisExtent实现自适应
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            mainAxisExtent: 80, maxCrossAxisExtent: 350),
        itemCount: fineClimbWebsites.length,
        itemBuilder: (context, index) {
          ClimbWebsite climbWebsite = fineClimbWebsites[index];
          return Card(
            elevation: 0,
            child: MaterialButton(
              padding: const EdgeInsets.all(0),
              onPressed: () => enterSourceDetail(climbWebsite),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ListTile(
                    title: Text(climbWebsite.name,
                        overflow: TextOverflow.ellipsis),
                    subtitle: _buildPingStatusRow(climbWebsite),
                    leading: WebSiteLogo(url: climbWebsite.iconUrl, size: 35),
                    trailing: _buildSwitchButton(climbWebsite),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildClimbWebsiteListItem(ClimbWebsite climbWebsite) {
    return ListTile(
        title: Row(
          children: [
            showPingDetail
                ? Container()
                : _getPingStatusIcon(climbWebsite.pingStatus),
            showPingDetail ? Container() : const SizedBox(width: 10),
            Text(climbWebsite.name),
          ],
        ),
        subtitle: showPingDetail ? _buildPingStatusRow(climbWebsite) : null,
        leading: WebSiteLogo(url: climbWebsite.iconUrl, size: 35),
        trailing: _buildSwitchButton(climbWebsite),
        onTap: () => enterSourceDetail(climbWebsite));
  }

  _buildClimbWebsiteListViewCard() {
    return Card(
      child: Column(
        children: [
          _buildCardTitle("搜索源"),
          _buildClimbWebsiteListView(),
          // 展开已弃用
          ExpandChild(
            child: _buildDiscardList(),
            collapsedHint: "展开",
            expandedHint: "收起",
            expandArrowStyle: ExpandArrowStyle.both,
          ),
        ],
      ),
    );
  }

  _buildClimbWebsiteListView() {
    return Column(
      children: [
        for (var climbWebsite in climbWebsites)
          climbWebsite.discard
              ? Container()
              : _buildClimbWebsiteListItem(climbWebsite),
      ],
    );
  }

  _buildDiscardList() {
    return Column(
        children: climbWebsites.map((climbWebsite) {
      if (!climbWebsite.discard) {
        return Container();
      }
      return _buildClimbWebsiteListItem(climbWebsite);
    }).toList());
  }

  _buildPingStatusRow(ClimbWebsite climbWebsite) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        climbWebsite.discard
            ? _getPingStatusIcon(PingStatus())
            : _getPingStatusIcon(climbWebsite.pingStatus),
        const SizedBox(width: 10),
        climbWebsite.discard
            ? const Text("无法使用", textScaleFactor: ThemeUtil.tinyScaleFactor)
            : Text(_getPingTimeStr(climbWebsite),
                textScaleFactor: ThemeUtil.tinyScaleFactor),
        const SizedBox(width: 10),
        // Text(e.comment)
      ],
    );
  }

  String _getPingTimeStr(ClimbWebsite e) {
    if (e.pingStatus.pinging) {
      return "测试中...";
    }
    if (e.pingStatus.needPing) {
      return "未知";
    }
    if (e.pingStatus.connectable) {
      return "${e.pingStatus.time}ms";
    }
    return "超时";
  }

  _getPingStatusIcon(PingStatus pingStatus) {
    return Icon(Icons.circle, size: 12, color: pingStatus.color);
  }

  void enterSourceDetail(ClimbWebsite climbWebsite) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return SourceDetail(climbWebsite);
    })).then((value) {
      setState(() {});
      // 可能从里面取消了启动
    });
  }

  _buildSwitchButton(ClimbWebsite climbWebsite) {
    if (climbWebsite.discard) {
      return null;
      // return IconButton(
      //     onPressed: () {
      //       showToast("很抱歉，该搜索源已经无法使用");
      //     },
      //     icon: const Icon(Icons.not_interested));
    }
    return IconButton(
      onPressed: () {
        _invertSource(climbWebsite);
      },
      icon: climbWebsite.enable
          ? Icon(Icons.check_box, color: ThemeUtil.getPrimaryColor())
          : const Icon(Icons.check_box_outline_blank),
    );
  }

  // 取消/启用搜索源
  void _invertSource(ClimbWebsite e) {
    e.enable = !e.enable;
    setState(() {}); // 使用的是StatefulBuilder的setState
    // 保存
    SPUtil.setBool(e.spkey, e.enable);
  }
}
