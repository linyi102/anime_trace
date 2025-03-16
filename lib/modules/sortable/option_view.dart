import 'package:animetrace/modules/sortable/sortable.dart';
import 'package:flutter/material.dart';

class SortOptionView extends StatelessWidget {
  const SortOptionView({
    super.key,
    required this.controller,
  });
  final SortController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(
            controller.modes.length,
            _buildOption,
          )
        ],
      ),
    );
  }

  Widget _buildOption(int index) {
    final mode = controller.modes[index];
    final selected = controller.curMode == mode;

    return ListTile(
      leading: SizedBox(
        height: 40,
        width: 40,
        child: selected
            ? controller.isReverse
                ? const Icon(Icons.arrow_downward)
                : const Icon(Icons.arrow_upward)
            : null,
      ),
      selected: selected,
      title: Text(mode.label),
      onTap: () {
        if (selected) {
          controller.changeReverse();
        } else {
          controller.changeMode(mode);
        }
      },
    );
  }
}
