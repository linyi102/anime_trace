import 'package:flutter/material.dart';

enum PageSwitchAnimation {
  zoom("放大", ZoomPageTransitionsBuilder()),
  cupertino("从右往左平移", CupertinoPageTransitionsBuilder()),
  fade("渐变", FadeTransitionsBuilder()),
  fadeUpwards("向上渐变", FadeUpwardsPageTransitionsBuilder()),
  openUpwards("向上展开", OpenUpwardsPageTransitionsBuilder());

  final String title;
  final PageTransitionsBuilder pageTransitionsBuilder;

  const PageSwitchAnimation(this.title, this.pageTransitionsBuilder);
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
