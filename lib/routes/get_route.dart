import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/shared_axis_transition_route.dart';
import 'package:get/get.dart';

class RouteUtil {
  static void getTo(dynamic page) {
    Get.to(page, transition: Transition.fadeIn);
  }

  static Future<T?> materialTo<T extends Object?>(
      BuildContext context, Widget widget) {
    return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => widget,
        ));
  }

  static Future<T?> sharedAxisTo<T extends Object?>(
    BuildContext context,
    Widget widget, {
    SharedAxisTransitionType transitionType =
        SharedAxisTransitionType.horizontal,
  }) {
    return Navigator.push(
        context,
        SharedAxisTransitionRoute(
          builder: (context) => widget,
          transitionType: transitionType,
        ));
  }

  static Future<T?> toImageViewer<T extends Object?>(
      BuildContext context, Widget widget) {
    return Navigator.push(
        context,
        SharedAxisTransitionRoute(
          builder: (context) => widget,
          transitionType: SharedAxisTransitionType.scaled,
        ));
  }

  static Future<T?> fadeTo<T extends Object?>(
      BuildContext context, Widget widget) {
    return Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              FadeTransition(
            opacity: animation,
            child: widget,
          ),
        ));
  }

  static Future<T?> scaleTo<T extends Object?>(
      BuildContext context, Widget widget) {
    return Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ScaleTransition(
            scale: animation,
            child: widget,
          ),
        ));
  }

  static Future<T?> noneAnimationTo<T extends Object?>(
      BuildContext context, Widget widget) {
    return Navigator.push(
        context,
        PageRouteBuilder(
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) => widget,
        ));
  }
}
