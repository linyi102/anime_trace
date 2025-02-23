import 'package:flutter/material.dart';
import 'package:animetrace/utils/platform.dart';

class CommonTabBarView extends StatelessWidget {
  const CommonTabBarView({super.key, required this.children, this.controller});
  final List<Widget> children;
  final TabController? controller;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: children,
      controller: controller,
      physics: PlatformUtil.tabBarViewPhysics,
    );
  }
}
