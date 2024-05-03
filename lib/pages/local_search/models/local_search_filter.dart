import 'package:flutter/material.dart';

class LocalSearchFilter {
  final String label;
  String selectedLabel;
  final IconData icon;
  final Widget filterView;
  LocalSearchFilter({
    required this.label,
    required this.icon,
    required this.filterView,
    this.selectedLabel = '',
  });

  LocalSearchFilter copyWith({
    String? label,
    IconData? icon,
    Widget? filterView,
  }) {
    return LocalSearchFilter(
      label: label ?? this.label,
      icon: icon ?? this.icon,
      filterView: filterView ?? this.filterView,
    );
  }

  @override
  String toString() =>
      'LocalSearchFilter(label: $label, icon: $icon, filterView: $filterView)';

  @override
  bool operator ==(covariant LocalSearchFilter other) {
    if (identical(this, other)) return true;

    return other.label == label &&
        other.icon == icon &&
        other.filterView == filterView;
  }

  @override
  int get hashCode => label.hashCode ^ icon.hashCode ^ filterView.hashCode;
}
