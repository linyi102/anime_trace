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
    return Theme(
      data: _getTabThemeData(),
      child: TabBar(
        tabs: tabs,
        controller: tabController,
        // true左对齐，false均分
        isScrollable: true,
        // 指示器
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
        labelColor: Theme.of(context).textTheme.titleMedium?.color,
        unselectedLabelColor: Theme.of(context).hintColor,
        labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamilyFallback: ThemeController.to.fontFamilyFallback,
            height: 1.1,
            fontWeight: FontWeight.w600),
        unselectedLabelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontFamilyFallback: ThemeController.to.fontFamilyFallback,
              height: 1.1,
            ),
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
    return Theme(
      data: _getTabThemeData(),
      child: Container(
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
          // 圆角
          splashBorderRadius: BorderRadius.circular(6),
          // 第三方指示器样式
          indicator: MaterialIndicator(
            horizontalPadding: 8,
            height: 4,
            color: Theme.of(context).primaryColor,
            paintingStyle: PaintingStyle.fill,
            bottomLeftRadius: radius,
            bottomRightRadius: radius,
            topLeftRadius: radius,
            topRightRadius: radius,
          ),
          labelColor: Theme.of(context).textTheme.titleMedium?.color,
          unselectedLabelColor: Theme.of(context).hintColor,
          labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontFamilyFallback: ThemeController.to.fontFamilyFallback,
                height: 1.1,
                fontWeight: FontWeight.w600,
              ),
          unselectedLabelStyle:
              Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontFamilyFallback: ThemeController.to.fontFamilyFallback,
                    height: 1.1,
                    fontWeight: FontWeight.normal,
                  ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

_getTabThemeData() {
  return ThemeData(
    splashColor: Colors.transparent,
    hoverColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );
}
