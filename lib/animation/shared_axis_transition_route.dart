import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

class SharedAxisTransitionRoute<T extends Object?> extends PageRoute<T> {
  SharedAxisTransitionRoute({
    required this.builder,
    required this.transitionType,
    this.transitionDuration = const Duration(milliseconds: 200),
    this.reverseTransitionDuration = const Duration(milliseconds: 150),
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor = Colors.transparent,
    this.barrierLabel = "",
    this.maintainState = true,
  });

  final WidgetBuilder builder;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  @override
  final bool opaque;

  @override
  final bool barrierDismissible;

  @override
  final Color barrierColor;

  @override
  final String barrierLabel;

  @override
  final bool maintainState;

  final SharedAxisTransitionType transitionType;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      builder(context);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: transitionType,
      child: child,
    );
  }
}
