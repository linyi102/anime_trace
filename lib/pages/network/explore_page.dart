import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_tab_bar.dart';
import 'package:flutter_test_future/pages/network/climb/anime_climb_all_website.dart';
import 'package:flutter_test_future/pages/network/directory/directory_page.dart';
import 'package:flutter_test_future/pages/network/sources/aggregate_page.dart';
import 'package:flutter_test_future/pages/network/update/update_record_page.dart';
import 'package:flutter_test_future/pages/network/weekly/weekly.dart';
import 'package:flutter_test_future/utils/platform.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/widgets/common_scaffold_body.dart';
import 'package:flutter_test_future/widgets/common_tab_bar_view.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

/// 探索页
class ExplorePage extends StatefulWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController; // 创建tab控制器
  final List<String> navs = ["聚合", "更新", "周表", "目录"];
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
        animationDuration: PlatformUtil.tabControllerAnimationDuration);
    // 添加监听器，记录最后一次的topTab的index
    _tabController.addListener(() {
      // Log.info("切换tab，tab.index=${_tabController.index}"); // doubt win端发现会连续输出两次
      if (_tabController.index == _tabController.animation!.value) {
        SPUtil.setInt("lastNavIndexInNetWorkNav", _tabController.index);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: _buildSearchBar(),
        bottom: CommonBottomTabBar(
          tabs: navs
              .map((e) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Tab(child: Text(e)),
                  ))
              .toList(),
          tabController: _tabController,
        ),
        actions: actions,
      ),
      body: CommonScaffoldBody(
        child: CommonTabBarView(controller: _tabController, children: const [
          AggregatePage(),
          UpdateRecordPage(),
          WeeklyPage(),
          DirectoryPage(),
        ]),
      ),
      // floatingActionButton: _buildFAB(context),
    );
  }

  _buildSearchBar() {
    var fg = Theme.of(context).hintColor;
    var radius = BorderRadius.circular(99);

    return Material(
      borderRadius: radius,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: InkWell(
        borderRadius: radius,
        onTap: _enterAnimeClimbAllWebsitePage,
        child: ClipRRect(
          borderRadius: radius,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(MingCuteIcons.mgc_search_line, size: 16, color: fg),
                      const SizedBox(width: 10),
                      Text('搜索动漫', style: TextStyle(fontSize: 14, color: fg)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _enterAnimeClimbAllWebsitePage() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return const AnimeClimbAllWebsite();
      },
    ));
  }
}
