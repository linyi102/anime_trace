import 'package:flutter/material.dart';

enum PageSwitchAnimation {
  zoom(1, "放大", ZoomPageTransitionsBuilder()),
  cupertino(2, "从右往左平移", CupertinoPageTransitionsBuilder()),
  fade(3, "渐变", FadeTransitionsBuilder()),
  fadeUpwards(4, "向上渐变", FadeUpwardsPageTransitionsBuilder()),
  openUpwards(5, "向上展开", OpenUpwardsPageTransitionsBuilder());

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
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
