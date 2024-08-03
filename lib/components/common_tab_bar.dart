import 'package:flutter/material.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';

class CommonTitleTabBar extends StatelessWidget {
  const CommonTitleTabBar({required this.tabs, this.tabController, super.key});
  final List<Widget> tabs;
  final TabController? tabController;
  double get radius => 99;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      tabs: tabs,
      controller: tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: MaterialIndicator(
        horizontalPadding: 5,
        height: 4,
        color: Theme.of(context).primaryColor,
        paintingStyle: PaintingStyle.fill,
        bottomLeftRadius: radius,
        bottomRightRadius: radius,
        topLeftRadius: radius,
        topRightRadius: radius,
      ),
      splashBorderRadius: BorderRadius.circular(6),
      unselectedLabelColor: Theme.of(context).hintColor,
      labelStyle: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class CommonBottomTabBar extends StatelessWidget
    implements PreferredSizeWidget {
  final List<Widget> tabs;
  final TabController? tabController;
  final bool isScrollable;
  final Color? bgColor;
  double get radius => 99;

  const CommonBottomTabBar(
      {required this.tabs,
      this.tabController,
      this.isScrollable = false,
      this.bgColor,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.only(start: 5, end: 5),
      alignment: Alignment.centerLeft,
      color: bgColor,
      child: TabBar(
        tabs: tabs,
        controller: tabController,
        // 居中，而不是靠左下
        padding: const EdgeInsets.all(2),
        // 清单可以滑动，避免拥挤
        isScrollable: isScrollable,
        tabAlignment: isScrollable ? TabAlignment.start : null,
        labelPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        indicatorSize: TabBarIndicatorSize.label,
        // 第三方指示器样式
        indicator: MaterialIndicator(
          horizontalPadding: 4,
          height: 4,
          color: Theme.of(context).primaryColor,
          paintingStyle: PaintingStyle.fill,
          bottomLeftRadius: radius,
          bottomRightRadius: radius,
          topLeftRadius: radius,
          topRightRadius: radius,
        ),
        splashBorderRadius: BorderRadius.circular(6),
        unselectedLabelColor: Theme.of(context).hintColor,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
