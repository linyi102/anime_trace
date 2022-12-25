import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/pages/network/fav_website_list_page.dart';
import 'package:flutter_test_future/pages/network/source_detail_page.dart';
import 'package:flutter_test_future/pages/network/update_record_page.dart';
import 'package:flutter_test_future/responsive.dart';
import 'package:flutter_test_future/utils/dio_package.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/ping_result.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:oktoast/oktoast.dart';

import '../modules/website_icon.dart';

class SourceListPage extends StatefulWidget {
  const SourceListPage({Key? key}) : super(key: key);

  @override
  State<SourceListPage> createState() => _SourceListPageState();
}

class _SourceListPageState extends State<SourceListPage> {
  bool showPingDetail = true; // true时ListTile显示副标题，并做出样式调整
  bool canClickPingButton = true; // 限制点击ping按钮(10s一次)。切换页面会重置(暂不打算改为全局变量)

  @override
  void initState() {
    super.initState();
    // 如果之前没有ping，才自动ping
    for (var website in climbWebsites) {
      if (website.pingStatus.notPing) {
        _pingAllWebsites();
        break; // ping所有，然后直接退出循环
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
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
      if (website.discard) continue;
      website.pingStatus.connectable = false;
      website.pingStatus.pinging = true; // 表示正在ping
    }
    setState(() {});
    // 不推荐await：第一个结束后，才会执行下一个
    // for (ClimbWebstie website in climbWebsites) {
    //   debugPrint("${website.name} ping...");
    //   website.pingOk = await DioPackage.ping(website.baseUrl);
    //   debugPrint("${website.name}:pingOk=${website.pingOk}");
    // }
    // 推荐then：同时执行
    for (var website in climbWebsites) {
      // debugPrint("${website.name} ping...");
      if (website.discard) continue;
      DioPackage.ping(website.climb.baseUrl).then((value) {
        website.pingStatus = value;
        if (mounted) {
          setState(() {});
        }

        debugPrint("${website.name}:pingStatus=${website.pingStatus}");
      });
    }
  }

  final bool _showPingButton = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _pingAllWebsites();
        },
        child: ListView(
          children: [
            // SizedBox(
            //   height: 80,
            //   child: ListView(
            //     scrollDirection: Axis.horizontal,
            //     children: climbWebsites
            //         .map((climbWebsite) => Container(
            //               padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
            //               width: 100,
            //               child: Column(
            //                 crossAxisAlignment: CrossAxisAlignment.center,
            //                 children: [
            //                   buildWebSiteIcon(
            //                       url: climbWebsite.iconUrl, size: 35),
            //                   Text(
            //                     climbWebsite.name,
            //                     overflow: TextOverflow.ellipsis,
            //                     style: const TextStyle(fontSize: 12),
            //                   ),
            //                   // _buildPingStatusRow(climbWebsite),
            //                   climbWebsite.discard
            //                       ? _getPingStatusIcon(PingStatus())
            //                       : _getPingStatusIcon(climbWebsite.pingStatus),
            //                 ],
            //               ),
            //             ))
            //         .toList(),
            //   ),
            // ),
            // Expanded(child: UpdateRecordPage())

            // _showPingButton ? _buildPingButton() : Container(),
            Responsive.isMobile(context) ? _buildListView() : _buildGridView(),

            // Responsive(
            //     mobile: _buildListView(),
            //     tablet: _buildGridView(crossAxisCount: 2),
            //     desktop:
            //         _buildGridView(crossAxisCount: size.width > 1100 ? 4 : 3)),

            FavWebsiteListPage()
          ],
        ),
      ),
    );
  }

  GridView _buildGridView({int crossAxisCount = 3}) {
    return GridView.builder(
        // 解决报错问题
        shrinkWrap: true,
        //解决不滚动问题
        physics: const NeverScrollableScrollPhysics(),
        // 改用WithMaxCrossAxisExtent实现自适应
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            mainAxisExtent: 80, maxCrossAxisExtent: 350),
        // gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        //     crossAxisCount: crossAxisCount, childAspectRatio: childAspectRatio),
        itemCount: climbWebsites.length,
        itemBuilder: (context, index) {
          ClimbWebsite climbWebsite = climbWebsites[index];
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
                    leading:
                        buildWebSiteIcon(url: climbWebsite.iconUrl, size: 35),
                    trailing: _buildSwitchButton(climbWebsite),
                  ),
                ],
              ),
            ),
          );
        });
  }

  ListView _buildListView() {
    return ListView(
        shrinkWrap: true, //解决无限高度问题
        physics: const NeverScrollableScrollPhysics(), //禁用滑动事件
        children: climbWebsites.map((climbWebsite) {
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
              subtitle:
                  showPingDetail ? _buildPingStatusRow(climbWebsite) : null,
              leading: buildWebSiteIcon(url: climbWebsite.iconUrl, size: 35),
              trailing: _buildSwitchButton(climbWebsite),
              onTap: () => enterSourceDetail(climbWebsite));
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
    // ping...在前，未知在后。因为DioPackage的ping方法只有在ping结束后才会设置pingNone为false
    if (e.pingStatus.notPing) {
      return "未知";
    }
    if (e.pingStatus.connectable) {
      return "${e.pingStatus.time}ms";
    }
    return "超时";
  }

  _getPingStatusIcon(PingStatus pingStatus) {
    return Icon(Icons.circle,
        size: 12,
        color: (pingStatus.notPing || pingStatus.pinging)
            ? Colors.grey // 还没ping过，或者正在ping
            : (pingStatus.connectable
                ? ThemeUtil.getConnectableColor()
                : Colors.red));
  }

  void enterSourceDetail(ClimbWebsite climbWebsite) {
    Navigator.of(context).push(FadeRoute(builder: (context) {
      return SourceDetail(climbWebsite);
    })).then((value) {
      setState(() {});
      // 可能从里面取消了启动
    });
  }

  IconButton _buildSwitchButton(ClimbWebsite climbWebsite) {
    if (climbWebsite.discard) {
      return IconButton(
          onPressed: () {
            showToast("很抱歉，该搜索源已经无法使用");
          },
          icon: const Icon(Icons.not_interested));
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

  _buildPingButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Card(
            elevation: 6,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(50))), // 圆角
            clipBehavior: Clip.antiAlias, // 设置抗锯齿，实现圆角背景
            child: MaterialButton(
              onPressed: _pingAllWebsites,
              child: Container(
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                child: const Text(
                  // "测试连接",
                  // "测试连通",
                  // "P I N G",
                  "ping",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
