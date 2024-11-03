import 'package:flutter/material.dart';
import 'package:flutter_test_future/widgets/animation/fade_in_up.dart';

class FloatingBottomActions extends StatefulWidget {
  const FloatingBottomActions({
    super.key,
    required this.children,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 8),
  });
  final List<Widget> children;
  final EdgeInsets itemPadding;

  @override
  State<FloatingBottomActions> createState() => _FloatingBottomActionsState();
}

class _FloatingBottomActionsState extends State<FloatingBottomActions> {
  @override
  Widget build(BuildContext context) {
    return FadeInUp(
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
              for (final child in widget.children)
                Padding(padding: widget.itemPadding, child: child)
            ]),
          ),
        ),
      ),
    );
  }
}
