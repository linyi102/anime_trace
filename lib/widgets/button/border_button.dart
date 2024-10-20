import 'package:flutter/material.dart';

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

    return Material(
      color: selected
          ? Theme.of(context).primaryColor.withOpacity(0.2)
          : Theme.of(context).cardColor,
      child: Ink(
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                  width: 1,
                  color: selected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).hintColor.withOpacity(0.1)),
              borderRadius: radius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
