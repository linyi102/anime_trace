import 'package:flutter/material.dart';
import 'package:animetrace/utils/extensions/color.dart';

class BorderButton extends StatelessWidget {
  const BorderButton({
    super.key,
    this.selected = false,
    required this.onTap,
    required this.child,
  });
  final bool selected;
  final GestureTapCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6);

    return ClipRRect(
      borderRadius: radius,
      child: Material(
        color: selected
            ? Theme.of(context).primaryColor.withOpacityFactor(0.2)
            : Theme.of(context).cardColor,
        child: Ink(
          child: InkWell(
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                    width: 1,
                    color: selected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).hintColor.withOpacityFactor(0.1)),
                borderRadius: radius,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
