import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class PercentBar extends StatelessWidget {
  final double percent;
  final double lineHeight;
  final EdgeInsets padding;
  const PercentBar({
    Key? key,
    this.percent = 0,
    this.lineHeight = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 10.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LinearPercentIndicator(
      padding: padding,
      percent: percent,
      lineHeight: lineHeight,
      animation: true,
      animateFromLastPercent: percent != 0,
      progressColor: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).disabledColor.withOpacity(0.1),
      barRadius: const Radius.circular(99),
    );
  }
}
