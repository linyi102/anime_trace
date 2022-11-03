import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_widget.dart';

class FadeAnimatedSwitcher extends StatelessWidget {
  final bool loadOk;
  final Widget destWidget;
  final Widget? specifiedLoadingWidget;
  const FadeAnimatedSwitcher(
      {Key? key,
      required this.loadOk,
      required this.destWidget,
      this.specifiedLoadingWidget})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (specifiedLoadingWidget != null) {
      return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: loadOk ? destWidget : specifiedLoadingWidget);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: loadOk
          ? destWidget
          : (specifiedLoadingWidget ??
              loadingWidget(context)), // 如果没有指定加载组件，则使用默认提供的
    );
  }
}
