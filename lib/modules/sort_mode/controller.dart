import 'package:flutter/material.dart';

import 'mode.dart';

class SortModeController<T> extends ChangeNotifier {
  final List<SortMode<T>> modes;
  late SortMode<T> curMode;
  late bool isReverse;
  final int defaultModeIndex;

  final List<T> Function() getOriList;
  final void Function(List<T> sortedList) onSorted;

  final void Function(SortMode mode) onModeChanged;
  final void Function(bool isReverse) onReverseChanged;

  SortModeController({
    required this.modes,
    required this.defaultModeIndex,
    required bool defaultReverse,
    required this.getOriList,
    required this.onSorted,
    required this.onModeChanged,
    required this.onReverseChanged,
  }) {
    curMode = modes.firstWhere(
      (e) => e.storeIndex == defaultModeIndex,
      orElse: () => modes.first,
    );
    isReverse = defaultReverse;
  }

  void sort() {
    onSorted(curMode.sort(getOriList(), isReverse));
  }

  void changeMode(SortMode<T> mode) {
    curMode = mode;
    onModeChanged(mode);
    sort();
    notifyListeners();
  }

  void changeReverse() {
    isReverse = !isReverse;
    onReverseChanged(isReverse);
    sort();
    notifyListeners();
  }
}
