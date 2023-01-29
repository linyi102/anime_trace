import 'package:flutter/material.dart';
import 'package:flutter_tab_indicator_styler/flutter_tab_indicator_styler.dart';

import '../utils/theme_util.dart';

class CommonTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget> tabs;
  final TabController? controller;
  final bool isScrollable;

  const CommonTabBar(
      {required this.tabs,
      this.controller,
      this.isScrollable = false,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.only(start: 5,end: 5),
      alignment: Alignment.centerLeft,
      child: TabBar(
        tabs: tabs,
        controller: controller,
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
