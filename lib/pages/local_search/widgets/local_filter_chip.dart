import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/local_search/controllers/local_search_controller.dart';
import 'package:flutter_test_future/pages/local_search/models/local_search_filter.dart';
import 'package:flutter_test_future/pages/local_search/views/local_filter_page.dart';
import 'package:flutter_test_future/utils/extensions/color.dart';
import 'package:flutter_test_future/utils/keyboard_util.dart';
import 'package:flutter_test_future/widgets/bottom_sheet.dart';

class LocalFilterChip extends StatefulWidget {
  const LocalFilterChip({
    required this.localSearchController,
    required this.filter,
    super.key,
  });
  final LocalSearchController localSearchController;
  final LocalSearchFilter filter;

  @override
  State<LocalFilterChip> createState() => _LocalFilterChipState();
}

class _LocalFilterChipState extends State<LocalFilterChip> {
  bool get selected => widget.filter.selectedLabel.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton.icon(
          onPressed: () {
            KeyboardUtil.cancelKeyBoard();
            showCommonModalBottomSheet(
              context: context,
              builder: (context) => LocalFilterPage(
                localSearchController: widget.localSearchController,
                filter: widget.filter,
              ),
            );
          },
          style: ButtonStyle(
            visualDensity: const VisualDensity(vertical: -2),
            padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16)),
            backgroundColor: selected
                ? WidgetStatePropertyAll(
                    Theme.of(context).primaryColor.withOpacityFactor(0.2))
                : null,
          ),
          icon: Icon(widget.filter.icon, size: 16),
          label: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                selected ? widget.filter.selectedLabel : widget.filter.label,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              if (selected) ...[
                const SizedBox(width: 5),
                InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () =>
                      widget.localSearchController.reset(widget.filter),
                  child: Container(
                      height: 18,
                      width: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context)
                            .primaryColor
                            .withOpacityFactor(0.2),
                      ),
                      child: const Icon(Icons.close, size: 14)),
                )
              ]
            ],
          )),
    );
  }
}
