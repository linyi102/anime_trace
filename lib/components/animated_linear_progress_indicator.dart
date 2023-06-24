import 'package:flutter/material.dart';

class AnimatedLinearProgressIndicator extends StatelessWidget {
  const AnimatedLinearProgressIndicator(
      {this.prevalue, required this.value, this.backgroundColor, super.key});
  final double? prevalue;
  final double value;
  final Color? backgroundColor;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      // 指定值范围[begin, end]后，会在200ms内提供多个value给LinearProgressIndicator，从而实现动画效果
      tween: Tween(begin: prevalue ?? value, end: value),
      duration: const Duration(milliseconds: 200),
      builder: (context, double value, child) => LinearProgressIndicator(
        value: value, // 使用tween提供的value
        backgroundColor: backgroundColor,
      ),
    );
  }
}
