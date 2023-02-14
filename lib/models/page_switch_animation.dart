import 'package:flutter/material.dart';

enum PageSwitchAnimation {
  zoom(1, "放大", ZoomPageTransitionsBuilder()),
  cupertino(2, "从右往左平移", CupertinoPageTransitionsBuilder()),
  fade(3, "渐变", FadeTransitionsBuilder());
  // fadeUpwards(4, "向上渐变", FadeUpwardsPageTransitionsBuilder()),
  // openUpwards(5, "向上展开", OpenUpwardsPageTransitionsBuilder());

  final int id;
  final String title;
  final PageTransitionsBuilder pageTransitionsBuilder;

  const PageSwitchAnimation(this.id, this.title, this.pageTransitionsBuilder);
}

class FadeTransitionsBuilder extends PageTransitionsBuilder {
  const FadeTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    // Log.info("${animation.value}");

    return FadeTransition(
      opacity: animation,
      child: child,
    );

    // 缺点：返回时没有效果
    // return TweenAnimationBuilder(
    //   tween: Tween(begin: 0.0, end: 1.0),
    //   duration: const Duration(milliseconds: 400),
    //   builder: (BuildContext context, double value, Widget? child1) {
    //     Log.info("value=$value");
    //     return Opacity(opacity: value, child: child);
    //   },
    // );

    // 同上
    // return FastFadeTransition(child: child);
  }
}

class FastFadeTransition extends StatefulWidget {
  final Widget child;

  const FastFadeTransition({required this.child, Key? key}) : super(key: key);

  @override
  State<FastFadeTransition> createState() => _FastFadeTransitionState();
}

class _FastFadeTransitionState extends State<FastFadeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this)
      ..forward();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: widget.child);
  }
}
