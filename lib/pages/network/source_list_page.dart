import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/climb_website.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/source_detail.dart';
import 'package:flutter_test_future/utils/dio_package.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:oktoast/oktoast.dart';

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

  final ScrollController _scrollController = ScrollController();
  @override
  void dispose() {
    //为了避免内存泄露，需要调用.dispose
    _scrollController.dispose();
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
      // DioPackage.ping("https://fonts.google.com/").then((value) {
      // DioPackage.ping("matcha-jp.com").then((value) {
      // DioPackage.ping("baidu.com").then((value) {
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
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _pingAllWebsites();
        },
        child: ListView(
          controller: _scrollController,
          children: [
            _showPingButton ? _buildPingButton() : Container(),
            ListView(
              shrinkWrap: true, //解决无限高度问题
              physics: const NeverScrollableScrollPhysics(), //禁用滑动事件
              children: _buildListTiles(),
            )
          ],
        ),
      ),
    );
  }

  String _getPingTimeStr(ClimbWebstie e) {
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

  _getPingStatusIcon(ClimbWebstie e) {
    return Icon(Icons.circle,
        size: 12,
        color: (e.pingStatus.notPing || e.pingStatus.pinging)
            ? Colors.grey // 还没ping过，或者正在ping
            : (e.pingStatus.connectable
                ? ThemeUtil.getConnectableColor()
                : Colors.red));
  }

  List<Widget> _buildListTiles() {
    return climbWebsites.map((e) {
      return ListTile(
        title: Row(
          children: [
            showPingDetail ? Container() : _getPingStatusIcon(e),
            showPingDetail ? Container() : const SizedBox(width: 10),
            Text(e.name),
          ],
        ),
        subtitle: showPingDetail
            ? Row(
                children: [
                  _getPingStatusIcon(e),
                  const SizedBox(width: 10),
                  Text(_getPingTimeStr(e)),
                  const SizedBox(width: 10),
                  // Text(e.comment)
                ],
              )
            : null,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.asset(
            e.iconAssetUrl,
            fit: BoxFit.cover,
            width: showPingDetail ? 35 : 25, // 没有副标题用25，有则用35
          ),
        ),
        trailing: IconButton(
          onPressed: () {
            _invertSource(e);
          },
          icon: e.enable
              ? Icon(Icons.check_box, color: ThemeUtil.getThemePrimaryColor())
              : const Icon(Icons.check_box_outline_blank),
        ),
        // 带缩放动画的开关图标
        // trailing: AnimatedSwitcher(
        //   duration: const Duration(milliseconds: 200),
        //   transitionBuilder:
        //       (Widget child, Animation<double> animation) {
        //     return ScaleTransition(
        //         child: child, scale: animation); // 缩放
        //   },
        //   child: e.enable
        //       ? Icon(Icons.check_box,
        //           key: Key(e.enable.toString()), // 不能用Unique()，否则会影响其他ListTile中的图标
        //           color: ThemeUtil.getThemePrimaryColor())
        //       : Icon(Icons.check_box_outline_blank,
        //           key: Key(e.enable.toString())),
        // ),
        onTap: () {
          Navigator.of(context).push(FadeRoute(builder: (context) {
            return SourceDetail(e);
          })).then((value) {
            setState(() {});
            // 可能从里面取消了启动
          });
        },
      );
    }).toList();
  }

  // 取消/启用搜索源
  void _invertSource(ClimbWebstie e) {
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
