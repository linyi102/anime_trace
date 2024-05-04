import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_tab_bar.dart';
import 'package:flutter_test_future/pages/local_search/controllers/local_search_controller.dart';
import 'package:flutter_test_future/pages/local_search/models/local_search_filter.dart';
import 'package:flutter_test_future/pages/local_search/widgets/select_view_action.dart';
import 'package:flutter_test_future/utils/platform.dart';
import 'package:flutter_test_future/widgets/common_tab_bar_view.dart';

class LocalFilterPage extends StatefulWidget {
  const LocalFilterPage({
    required this.localSearchController,
    required this.filter,
    super.key,
  });
  final LocalSearchController localSearchController;
  final LocalSearchFilter filter;

  @override
  State<LocalFilterPage> createState() => _LocalFilterPageState();
}

class _LocalFilterPageState extends State<LocalFilterPage>
    with SingleTickerProviderStateMixin {
  late LocalSearchFilter curFilter;
  List<LocalSearchFilter> get filters => widget.localSearchController.filters;

  late TabController tabController;

  @override
  void initState() {
    super.initState();
    curFilter = filters.first;
    tabController = TabController(
      initialIndex: filters.indexWhere((element) => element == widget.filter),
      length: filters.length,
      vsync: this,
      animationDuration: PlatformUtil.tabControllerAnimationDuration,
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: CommonBottomTabBar(
            isScrollable: true,
            tabController: tabController,
            tabs: [...filters.map((e) => Tab(child: Text(e.label)))]),
      ),
      body: CommonTabBarView(
          controller: tabController,
          children: [...filters.map((e) => e.filterView)]),
      bottomNavigationBar: SelectViewAction(
        onReset: widget.localSearchController.resetAll,
        onApply: () {
          // 每切换过滤条件都会进行搜索，因此点击确定后不用再次搜索
          // widget.localSearchController.search();
        },
      ),
    );
  }
}
