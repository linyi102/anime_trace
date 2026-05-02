import 'package:flutter/material.dart';

class ConnectedButtonItem<T> {
  final Widget? icon;
  final String label;
  final T value;

  const ConnectedButtonItem({
    this.icon,
    required this.label,
    required this.value,
  });
}

class ConnectedButtonGroups<T> extends StatefulWidget {
  const ConnectedButtonGroups({
    super.key,
    required this.items,
    required this.selected,
    this.onSelectionChanged,
    this.emptySelectionAllowed = false,
    this.multiSelectionEnabled = false,
  })  : assert(items.length > 0),
        assert(selected.length > 0 || emptySelectionAllowed),
        assert(selected.length < 2 || multiSelectionEnabled);

  final List<ConnectedButtonItem<T>> items;
  final Set<T> selected;
  final void Function(Set<T>)? onSelectionChanged;
  final bool emptySelectionAllowed;
  final bool multiSelectionEnabled;

  @override
  State<ConnectedButtonGroups<T>> createState() =>
      _ConnectedButtonGroupsState<T>();
}

class _ConnectedButtonGroupsState<T> extends State<ConnectedButtonGroups<T>> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < widget.items.length; i++)
          Expanded(child: _buildItem(i)),
      ],
    );
  }

  Widget _buildItem(int itemIndex) {
    final item = widget.items[itemIndex];
    final isSelected = widget.selected.contains(item.value);
    const radius1 = Radius.circular(90);
    const radius2 = Radius.circular(8);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: () {
          if (!widget.multiSelectionEnabled) {
            if (isSelected && !widget.emptySelectionAllowed) return;
            widget.onSelectionChanged?.call(isSelected ? {} : {item.value});
            return;
          }

          final newSelected = {...widget.selected};
          if (isSelected) {
            newSelected.remove(item.value);
          } else {
            newSelected.add(item.value);
          }
          widget.onSelectionChanged?.call(newSelected);
        },
        child: AnimatedContainer(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: isSelected || widget.items.length == 1
                ? const BorderRadius.all(radius1)
                : itemIndex == 0
                    ? const BorderRadius.horizontal(
                        left: radius1, right: radius2)
                    : itemIndex == widget.items.length - 1
                        ? const BorderRadius.horizontal(
                            left: radius2, right: radius1)
                        : const BorderRadius.all(radius2),
          ),
          duration: const Duration(milliseconds: 200),
          curve: Curves.decelerate,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (item.icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconTheme(
                    data: IconThemeData(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSecondary
                          : Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    child: item.icon!,
                  ),
                ),
              Text(
                item.label,
                style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSecondary
                        : Theme.of(context).colorScheme.onSecondaryContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
