import 'package:flutter/material.dart';
import 'package:flutter_test_future/widgets/common_divider.dart';

class DividerScaffoldBody extends StatelessWidget {
  const DividerScaffoldBody({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Column(
        children: [
          const CommonDivider(),
          Expanded(child: child),
        ],
      ),
    );
  }
}
