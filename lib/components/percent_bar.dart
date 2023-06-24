import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class PercentBar extends StatelessWidget {
  final double percent;
  const PercentBar(this.percent, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LinearPercentIndicator(
      lineHeight: 12,
      animation: true,
      animateFromLastPercent: true,
      percent: percent,
      progressColor: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).disabledColor,
      barRadius: const Radius.circular(24),
    );
  }
}
