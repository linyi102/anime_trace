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
      physics: PlatformUtil.pageViewPhysics,
    );
  }
}

class FastPageScrollPhysics extends ScrollPhysics {
  const FastPageScrollPhysics({super.parent});

  @override
  FastPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FastPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring =>
      SpringDescription.withDampingRatio(mass: 0.5, stiffness: 500, ratio: 1.1);
}
