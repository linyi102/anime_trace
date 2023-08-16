import 'package:flutter/material.dart';

class CommonDivider extends StatelessWidget {
  const CommonDivider({
    super.key,
    this.thinkness = 0.5,
    this.direction = Axis.horizontal,
    this.padding = EdgeInsets.zero,
    this.color,
  });
  final double thinkness;
  final Axis direction;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    var defaultColor = Theme.of(context).dividerColor;

    if (direction == Axis.vertical) {
      return Padding(
          padding: padding, child: VerticalDivider(width: thinkness));
    }
    return Container(
      height: thinkness,
      margin: padding,
      color: color ?? defaultColor,
    );
  }
}
