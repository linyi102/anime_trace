import 'package:flutter/material.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/pages/directory_page.dart';
import 'package:flutter_test_future/pages/source_list_page.dart';
import 'package:flutter_test_future/scaffolds/anime_climb_all_website.dart';
import 'package:flutter_test_future/utils/sp_util.dart';

// 导航栏，顶部分为搜索源和目录
class NetWorkNav extends StatefulWidget {
  const NetWorkNav({Key? key}) : super(key: key);

  @override
  State<NetWorkNav> createState() => _NetWorkNavState();
}

class _NetWorkNavState extends State<NetWorkNav>
    with SingleTickerProviderStateMixin {
  late TabController _tabController; // 创建tab控制器
  final List<String> navs = ["搜索源", "目录"];

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
      if (_tabController.index == _tabController.animation!.value) {
        SPUtil.setInt("lastNavIndexInNetWorkNav", _tabController.index);
      }
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
          title: const Text(
            "网络",
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          bottom: PreferredSize(
              // 默认情况下，要将标签栏与相同的标题栏高度对齐，可以使用常量kToolbarHeight
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  tabs: navs.map((e) => Tab(child: Text(e))).toList(),
                  controller: _tabController, // 指定tab控制器
                  padding: const EdgeInsets.all(2), // 居中，而不是靠左下
                  // isScrollable: true, // 标签可以滑动，避免拥挤
                  labelPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                  indicatorColor: Colors.transparent, // 隐藏
                  indicatorSize: TabBarIndicatorSize.label, // 指示器长短和标签一样
                  indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.blue),
                  indicatorPadding:
                      const EdgeInsets.only(left: 5, right: 5, top: 45),
                  indicatorWeight: 3, // 指示器高度
                ),
              ))),
      body: TabBarView(controller: _tabController, // 指定tab控制器
          children: const [
            SourceListPage(),
            DirectoryPage(),
          ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
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
