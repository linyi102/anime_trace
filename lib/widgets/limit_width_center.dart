import 'package:flutter/material.dart';

class AlignLimitedBox extends StatelessWidget {
  const AlignLimitedBox({
    super.key,
    this.alignment = Alignment.center,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
    this.child,
  });
  final double maxWidth;
  final double maxHeight;
  final Widget? child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: child,
      ),
    );
  }
}
