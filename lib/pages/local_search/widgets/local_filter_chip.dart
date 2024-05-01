import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/local_search/models/local_search_filter.dart';
import 'package:flutter_test_future/pages/local_search/views/local_filter_page.dart';
import 'package:flutter_test_future/widgets/bottom_sheet.dart';

class LocalFilterChip extends StatefulWidget {
  const LocalFilterChip({
    required this.filter,
    super.key,
  });
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
            showCommonModalBottomSheet(
              context: context,
              builder: (context) => LocalFilterPage(filter: widget.filter),
            );
          },
          style: ButtonStyle(
            visualDensity: const VisualDensity(vertical: -2),
            padding: const MaterialStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16)),
            backgroundColor: selected
                ? MaterialStatePropertyAll(
                    Theme.of(context).primaryColor.withOpacity(0.2))
                : null,
          ),
          icon: Icon(widget.filter.icon, size: 16),
          label: Text(
            selected ? widget.filter.selectedLabel : widget.filter.label,
            style: const TextStyle(fontSize: 14, height: 1.1),
          )),
    );
  }
}
