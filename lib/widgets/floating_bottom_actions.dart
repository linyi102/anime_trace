import 'package:flutter/material.dart';
import 'package:animetrace/widgets/animation/fade_in_up.dart';

class FloatingBottomActions extends StatelessWidget {
  const FloatingBottomActions({
    super.key,
    required this.children,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 8),
    this.display = true,
  });
  final List<Widget> children;
  final EdgeInsets itemPadding;
  final bool display;

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      animate: display,
      child: Container(
        alignment: Alignment.bottomCenter,
        child: Card(
          elevation: 2,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (final child in children)
                Padding(padding: itemPadding, child: child)
            ]),
          ),
        ),
      ),
    );
  }
}
