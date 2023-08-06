import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
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
      // true左对齐，false均分
      isScrollable: true,
      // 指示器
      indicatorSize: TabBarIndicatorSize.label,
      indicator: MaterialIndicator(
        horizontalPadding: 5,
        height: 3,
        color: Theme.of(context).primaryColor,
        paintingStyle: PaintingStyle.fill,
        bottomLeftRadius: radius,
        bottomRightRadius: radius,
        topLeftRadius: radius,
        topRightRadius: radius,
      ),
      // indicatorColor: Colors.transparent,
      // 圆角+取消波纹扩散
      splashBorderRadius: BorderRadius.circular(6),
      splashFactory: NoSplash.splashFactory,
      // 文字
      // labelPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      // labelStyle: Theme.of(context).textTheme.titleLarge,
      // unselectedLabelStyle: Theme.of(context).textTheme.titleSmall,
      labelColor: Theme.of(context).textTheme.titleLarge?.color,
      unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
      labelStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamilyFallback: ThemeController.to.fontFamilyFallback,
            height: 1.1,
          ),
      unselectedLabelStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamilyFallback: ThemeController.to.fontFamilyFallback,
            height: 1.1,
          ),
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
        labelPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        indicatorSize: TabBarIndicatorSize.label,
        // 圆角+取消波纹扩散
        splashBorderRadius: BorderRadius.circular(5),
        splashFactory: NoSplash.splashFactory,
        // 第三方指示器样式
        indicator: MaterialIndicator(
          horizontalPadding: 5,
          color: Theme.of(context).primaryColor,
          paintingStyle: PaintingStyle.fill,
          bottomLeftRadius: radius,
          bottomRightRadius: radius,
          topLeftRadius: radius,
          topRightRadius: radius,
        ),
        labelColor: Theme.of(context).textTheme.titleLarge?.color,
        unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
