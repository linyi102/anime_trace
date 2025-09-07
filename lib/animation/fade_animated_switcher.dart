import 'package:flutter/material.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:sliver_tools/sliver_tools.dart';

class FadeAnimatedSwitcher extends StatelessWidget {
  final bool loadOk;
  final Widget destWidget;
  final Widget? specifiedLoadingWidget;
  final Duration? duration;
  final bool sliver;
  final StackFit stackFit;

  const FadeAnimatedSwitcher({
    Key? key,
    required this.loadOk,
    required this.destWidget,
    this.specifiedLoadingWidget,
    this.duration,
    this.sliver = false,
    this.stackFit = StackFit.loose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final resolvedDuration = duration ?? const Duration(milliseconds: 200);
    final child = loadOk
        ? destWidget
        : (specifiedLoadingWidget ?? loadingWidget(context));

    return sliver
        ? SliverAnimatedSwitcher(duration: resolvedDuration, child: child)
        : AnimatedSwitcher(
            duration: resolvedDuration,
            child: child,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.center,
                fit: stackFit,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            });
  }
}
