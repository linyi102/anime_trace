import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/climb_website.dart';
import 'package:flutter_test_future/utils/dio_package.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  bool showPingDetail = true; // true时ListTile显示副标题，并做出样式调整

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

  void _pingAllWebsites() {
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
      DioPackage.ping(website.baseUrl).then((value) {
        website.pingStatus = value;
        setState(() {});

        debugPrint("${website.name}:pingStatus=${website.pingStatus}");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "测试页面",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("显示详细"),
            onTap: () {
              showPingDetail = !showPingDetail;
              setState(() {});
            },
          ),
          ListTile(
            title: const Text("测试连通"),
            onTap:
                _pingAllWebsites, // 如果函数定义没有声明void，且该处添加了括号：onTap: _pingAllWebsites()，则会一直调用
          ),
          ListView(
            shrinkWrap: true, //解决无限高度问题
            physics: const NeverScrollableScrollPhysics(), //禁用滑动事件
            children: _buildListTiles(),
          )
        ],
      ),
    );
  }

  String _getPingTimeStr(ClimbWebstie e) {
    if (e.pingStatus.pinging) {
      return "ping...";
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
            : (e.pingStatus.connectable ? Colors.green : Colors.red));
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
            fit: BoxFit.fitWidth,
            width: showPingDetail ? 35 : 25, // 没有副标题用25，有则用35
          ),
        ),
        trailing: e.enable
            ?  Icon(Icons.check_box,
                color: ThemeUtil.getThemePrimaryColor())
            : const Icon(Icons.check_box_outline_blank),
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
          e.enable = !e.enable;
          setState(() {}); // 使用的是StatefulBuilder的setState
          // 保存
          SPUtil.setBool(e.spkey, e.enable);
        },
      );
    }).toList();
  }
}
