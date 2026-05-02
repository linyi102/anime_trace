import 'package:animetrace/pages/anime_collection/checklist_controller.dart';
import 'package:animetrace/utils/sp_util.dart';
import 'package:flutter/material.dart';

class AutoMoveChecklistDialog extends StatefulWidget {
  const AutoMoveChecklistDialog({
    super.key,
    required this.initialTag,
    required this.onSelected,
  });
  final String initialTag;
  final void Function(String tag) onSelected;

  @override
  State<AutoMoveChecklistDialog> createState() =>
      _AutoMoveChecklistDialogState();
}

class _AutoMoveChecklistDialogState extends State<AutoMoveChecklistDialog> {
  late String selectedFinishedTag = widget.initialTag;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("移动清单"),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("已观看最后一集，是否移动清单？\n"),
            DropdownMenu<String>(
                requestFocusOnTap: false,
                initialSelection: selectedFinishedTag,
                dropdownMenuEntries: ChecklistController.to.tags
                    .map((e) => DropdownMenuEntry(label: e, value: e))
                    .toList(),
                onSelected: (value) {
                  selectedFinishedTag = value ?? selectedFinishedTag;
                  setState(() {});
                })
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () {
              SPUtil.setBool("showModifyChecklistDialog", false);
              Navigator.pop(context);
            },
            child: const Text("不再提醒")),
        TextButton(
            onPressed: () {
              SPUtil.setBool("autoMoveToFinishedTag", true);
              SPUtil.setString("selectedFinishedTag", selectedFinishedTag);
              widget.onSelected(selectedFinishedTag);
              Navigator.pop(context);
            },
            child: const Text("总是")),
        TextButton(
          onPressed: () {
            SPUtil.setString("selectedFinishedTag", selectedFinishedTag);
            widget.onSelected(selectedFinishedTag);
            Navigator.pop(context);
          },
          child: const Text("仅本次"),
        )
      ],
    );
  }
}
