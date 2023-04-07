import 'package:flutter/material.dart';
import 'package:flutter_tab_indicator_styler/flutter_tab_indicator_styler.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';

import '../utils/theme_util.dart';

class CommonTitleTabBar extends StatelessWidget {
  const CommonTitleTabBar({required this.tabs, this.tabController, super.key});
  final List<Widget> tabs;
  final TabController? tabController;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      tabs: tabs,
      controller: tabController,
      // true均分，false左对齐
      // isScrollable: true,
      // 指示器
      indicatorSize: TabBarIndicatorSize.label,
      indicatorColor: Colors.transparent,
      // 圆角+取消波纹扩散
      splashBorderRadius: BorderRadius.circular(6),
      splashFactory: NoSplash.splashFactory,
      // 文字
      labelPadding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      labelColor: ThemeUtil.getFontColor(),
      // labelStyle: Theme.of(context).textTheme.titleLarge,
      // unselectedLabelStyle: Theme.of(context).textTheme.titleSmall,
      labelStyle: TextStyle(
          fontSize: 18,
          color: ThemeUtil.getFontColor(),
          fontWeight: FontWeight.w600,
          fontFamilyFallback: ThemeController.to.fontFamilyFallback),
      unselectedLabelStyle: TextStyle(
          fontSize: 14,
          color: ThemeUtil.getCommentColor(),
          fontFamilyFallback: ThemeController.to.fontFamilyFallback),
    );
  }
}

class CommonBottomTabBar extends StatelessWidget
    implements PreferredSizeWidget {
  final List<Widget> tabs;
  final TabController? tabController;
  final bool isScrollable;
  final Color? bgColor;

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
          color: ThemeUtil.getPrimaryColor(),
          paintingStyle: PaintingStyle.fill,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
