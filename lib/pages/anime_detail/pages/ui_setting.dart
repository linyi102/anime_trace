import 'package:flutter/material.dart';
import 'package:animetrace/components/common_tab_bar.dart';
import 'package:animetrace/utils/platform.dart';
import 'package:animetrace/widgets/common_tab_bar_view.dart';

/// 动漫详情页ui和集排序设置
class AnimeDetailUISettingPage extends StatefulWidget {
  const AnimeDetailUISettingPage(
      {required this.sortPage,
      required this.uiPage,
      this.transparent = false,
      super.key});
  final Widget sortPage;
  final Widget uiPage;
  final bool transparent; // 拖动封面背景高度时添加透明度

  @override
  State<AnimeDetailUISettingPage> createState() =>
      _AnimeDetailUISettingPageState();
}

class _AnimeDetailUISettingPageState extends State<AnimeDetailUISettingPage>
    with SingleTickerProviderStateMixin {
  final List<String> tabStr = ["排序", "界面"];

  late final TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(
        length: tabStr.length,
        vsync: this,
        animationDuration: PlatformUtil.tabControllerAnimationDuration);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.transparent ? 0.4 : 1,
      child: Scaffold(
          appBar: CommonBottomTabBar(
              tabController: tabController,
              tabs: tabStr.map((e) => Tab(text: e)).toList()),
          body: CommonTabBarView(controller: tabController, children: [
            widget.sortPage,
            widget.uiPage,
          ])),
    );
  }
}
