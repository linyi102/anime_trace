import 'package:flutter/material.dart';
import 'package:flutter_tab_indicator_styler/flutter_tab_indicator_styler.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/pages/network/climb/anime_climb_all_website.dart';
import 'package:flutter_test_future/pages/network/directory_page.dart';
import 'package:flutter_test_future/pages/network/source_list_page.dart';
import 'package:flutter_test_future/pages/network/update_record_page.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:fluttericon/entypo_icons.dart';

/// 与网络相关的页面
class NetWorkPage extends StatefulWidget {
  const NetWorkPage({Key? key}) : super(key: key);

  @override
  State<NetWorkPage> createState() => _NetWorkPageState();
}

class _NetWorkPageState extends State<NetWorkPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController; // 创建tab控制器
  final List<String> navs = ["搜索源", "更新", "目录"];
  List<Widget> actions = [];

  @override
  void initState() {
    super.initState();
    // 顶部tab控制器
    _tabController = TabController(
      initialIndex: SPUtil.getInt("lastNavIndexInNetWorkNav",
          defaultValue: 0), // 设置初始index
      length: navs.length,
      vsync: this,
    );
    // 添加监听器，记录最后一次的topTab的index
    _tabController.addListener(() {
      // debugPrint("切换tab，tab.index=${_tabController.index}"); // doubt win端发现会连续输出两次
      if (_tabController.index == _tabController.animation!.value) {
        SPUtil.setInt("lastNavIndexInNetWorkNav", _tabController.index);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose(); // 销毁
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              const Text("网络", style: TextStyle(fontWeight: FontWeight.w600)),
          actions: actions,
          bottom: PreferredSize(
              // 默认情况下，要将标签栏与相同的标题栏高度对齐，可以使用常量kToolbarHeight
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  tabs: navs
                      .map((e) => Tab(
                          child: Text(e,
                              textScaleFactor: ThemeUtil.smallScaleFactor)))
                      .toList(),
                  // 指定tab控制器
                  controller: _tabController,
                  // 标签可以滑动，避免拥挤
                  isScrollable: false,
                  // 指示器长短和标签一样
                  labelPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  // 第三方指示器样式
                  indicatorSize: TabBarIndicatorSize.label,
                  indicator: MaterialIndicator(
                    color: ThemeUtil.getPrimaryColor(),
                    paintingStyle: PaintingStyle.fill,
                  ),
                ),
              ))),
      body: TabBarView(controller: _tabController, // 指定tab控制器
          children: [
            const SourceListPage(),
            UpdateRecordPage(),
            const DirectoryPage(),
          ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ThemeUtil.getPrimaryColor(),
        foregroundColor: Colors.white,
        child: const Icon(Entypo.search),
        onPressed: () {
          Navigator.of(context).push(FadeRoute(
            builder: (context) {
              return const AnimeClimbAllWebsite();
            },
          ));
        },
      ),
    );
  }
}
