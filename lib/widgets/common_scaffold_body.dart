import 'package:flutter/material.dart';
import 'package:flutter_test_future/widgets/common_divider.dart';

class CommonScaffoldBody extends StatelessWidget {
  const CommonScaffoldBody({super.key, required this.child});
  final Widget child;
  bool get dividerStyle => false;

  @override
  Widget build(BuildContext context) {
    return dividerStyle
        ? Material(
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: Column(
              children: [
                const CommonDivider(),
                Expanded(child: child),
              ],
            ),
          )
        : child;
  }
}
