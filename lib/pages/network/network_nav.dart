import 'package:flutter/material.dart';
import 'package:flutter_tab_indicator_styler/flutter_tab_indicator_styler.dart';
import 'package:flutter_test_future/components/dialog/dialog_update_all_anime_progress.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/pages/network/directory_page.dart';
import 'package:flutter_test_future/pages/network/source_list_page.dart';
import 'package:flutter_test_future/pages/network/update_record_page.dart';
import 'package:flutter_test_future/scaffolds/anime_climb_all_website.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';

// 导航栏，顶部分为搜索源和目录
class NetWorkNav extends StatefulWidget {
  const NetWorkNav({Key? key}) : super(key: key);

  @override
  State<NetWorkNav> createState() => _NetWorkNavState();
}

class _NetWorkNavState extends State<NetWorkNav>
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
    tryAddOrDelUpdateAnimeButtonAction(); // 点击网络页面，就是动漫更新记录页面，直接添加。因为下面的监听器监听不到(index没变)
    // 添加监听器，记录最后一次的topTab的index
    _tabController.addListener(() {
      // debugPrint("切换tab，tab.index=${_tabController.index}"); // doubt win端发现会连续输出两次
      if (_tabController.index == _tabController.animation!.value) {
        SPUtil.setInt("lastNavIndexInNetWorkNav", _tabController.index);
      }
      tryAddOrDelUpdateAnimeButtonAction();
      setState(() {});
    });
  }

  tryAddOrDelUpdateAnimeButtonAction() {
    Key updateRecordButtonKey = const Key("20220718224429");
    // final UpdateRecordController
    if (_tabController.index == 1) {
      // 遍历所有图标，如果不存在该key则添加
      actions.firstWhere((element) => element.key == updateRecordButtonKey,
          orElse: () {
        actions.add(IconButton(
            key: updateRecordButtonKey,
            onPressed: () {
              // 先更新动漫信息，再重新获取数据库表中的动漫更新记录(方法内会执行)
              // ClimbAnimeUtil.updateAllAnimesInfo();
              ClimbAnimeUtil.updateAllAnimesInfo().then((value) {
                if (value) {
                  dialogUpdateAllAnimeProgress(context);
                }
              });
            },
            icon: const Icon(Icons.refresh_rounded)));
        return Container();
      });
    } else {
      // 如果不是更新动漫tab，则删除更新动漫按钮
      actions.removeWhere((element) => element.key == updateRecordButtonKey);
    }
    setState(() {});
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
          title: const Text(
            "网络",
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: actions,
          bottom: PreferredSize(
              // 默认情况下，要将标签栏与相同的标题栏高度对齐，可以使用常量kToolbarHeight
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  tabs: navs.map((e) => Tab(child: Text(e))).toList(),
                  controller: _tabController,
                  // 指定tab控制器
                  padding: const EdgeInsets.all(2),
                  // 居中，而不是靠左下
                  isScrollable: false, // 标签可以滑动，避免拥挤
                  labelPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                  // 指示器长短和标签一样
                  indicatorSize: TabBarIndicatorSize.label,
                  // 第三方指示器样式
                  indicator: MaterialIndicator(
                    color: ThemeUtil.getThemePrimaryColor(),
                    paintingStyle: PaintingStyle.fill,
                  ),
                ),
              ))),
      body: TabBarView(controller: _tabController, // 指定tab控制器
          children:  [
            const SourceListPage(),
            UpdateRecordPage(),
            const DirectoryPage(),
          ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ThemeUtil.getThemePrimaryColor(),
        foregroundColor: Colors.white,
        child: const Icon(Icons.search_rounded),
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
