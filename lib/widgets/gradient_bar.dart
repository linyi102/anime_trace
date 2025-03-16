import 'package:flutter/material.dart';
import 'package:animetrace/utils/extensions/color.dart';

class GradientBar extends StatelessWidget {
  const GradientBar({this.child, this.reverse = false, this.height, super.key});
  final Widget? child;
  final bool reverse; // 默认从上到下渐变到透明，为true时从下到上
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: reverse ? Alignment.bottomCenter : Alignment.topCenter,
              end: reverse ? Alignment.topCenter : Alignment.bottomCenter,
              colors: [
            // Colors.black,
            // Colors.black.withOpacity(0.8),
            Colors.black.withOpacityFactor(0.5),
            // Colors.black.withOpacity(0.2),
            Colors.transparent,
          ])),
      child: child,
    );
  }
}
