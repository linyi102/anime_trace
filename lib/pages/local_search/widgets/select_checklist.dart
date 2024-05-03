import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/anime_collection/checklist_controller.dart';
import 'package:flutter_test_future/pages/local_search/controllers/local_search_controller.dart';
import 'package:flutter_test_future/pages/local_search/models/local_select_filter.dart';
import 'package:get/get.dart';

class SelectChecklistView extends StatefulWidget {
  const SelectChecklistView({required this.localSearchController, super.key});
  final LocalSearchController localSearchController;

  @override
  State<SelectChecklistView> createState() => _SelectChecklistViewState();
}

class _SelectChecklistViewState extends State<SelectChecklistView> {
  final checklistController = ChecklistController.to;

  LocalSelectFilter get localSelectFilter =>
      widget.localSearchController.localSelectFilter;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: widget.localSearchController,
      tag: widget.localSearchController.tag,
      builder: (_) => Scaffold(
        body: ListView.builder(
          itemCount: checklistController.tags.length,
          itemBuilder: (context, index) {
            final checklist = checklistController.tags[index];
            return RadioListTile(
                title: Text(checklist),
                toggleable: true,
                value: checklist,
                groupValue: localSelectFilter.checklist,
                onChanged: (value) {
                  widget.localSearchController.setChecklist(value);
                });
          },
        ),
      ),
    );
  }
}
