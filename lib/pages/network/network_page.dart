import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_tab_bar.dart';
import 'package:flutter_test_future/pages/network/climb/anime_climb_all_website.dart';
import 'package:flutter_test_future/pages/network/directory/directory_page.dart';
import 'package:flutter_test_future/pages/network/sources/aggregate_page.dart';
import 'package:flutter_test_future/pages/network/update/update_record_page.dart';
import 'package:flutter_test_future/pages/network/weekly/weekly.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/widgets/divider_scaffold_body.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

/// 与网络相关的页面
class NetWorkPage extends StatefulWidget {
  const NetWorkPage({Key? key}) : super(key: key);

  @override
  State<NetWorkPage> createState() => _NetWorkPageState();
}

class _NetWorkPageState extends State<NetWorkPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController; // 创建tab控制器
  final List<String> navs = ["聚合", "更新", "时间表", "目录"];
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
      // Log.info("切换tab，tab.index=${_tabController.index}"); // doubt win端发现会连续输出两次
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Row(
          children: [
            // const Text('探索'),
            // const SizedBox(width: 15),
            Expanded(child: _buildSearchBar())
          ],
        ),
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
      body: DividerScaffoldBody(
        child: TabBarView(
            controller: _tabController, // 指定tab控制器
            children: [
              const AggregatePage(),
              UpdateRecordPage(),
              const WeeklyPage(),
              const DirectoryPage(),
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
                      Icon(
                        MingCuteIcons.mgc_search_line,
                        size: 16,
                        color: fg,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '搜索动漫',
                        style: TextStyle(
                          fontSize: 14,
                          color: fg,
                        ),
                      ),
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

  FloatingActionButton _buildFAB() {
    return FloatingActionButton(
      child: const Icon(
        Icons.search,
        // MingCuteIcons.mgc_search_line,
      ),
      onPressed: _enterAnimeClimbAllWebsitePage,
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
