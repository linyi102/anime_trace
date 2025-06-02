import 'package:flutter/widgets.dart';

extension ListSortHelper<T> on List<T> {
  List<T> sorted([int Function(T a, T b)? compare]) {
    final copied = [...this]..sort(compare);
    return copied;
  }
}

extension WidgetListHelper on List<Widget> {
  List<Widget> joinWidget(Widget widget) {
    if (isEmpty) return [];

    final children = <Widget>[];
    for (int i = 0; i < length; i++) {
      children.add(this[i]);
      if (i != length - 1) {
        children.add(widget);
      }
    }
    return children;
  }
}
