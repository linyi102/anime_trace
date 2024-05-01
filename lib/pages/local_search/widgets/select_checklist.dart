import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/anime_collection/checklist_controller.dart';
import 'package:flutter_test_future/pages/local_search/controllers/local_search_controller.dart';
import 'package:flutter_test_future/pages/local_search/models/local_select_filter.dart';
import 'package:get/get.dart';

class SelectChecklistView extends StatefulWidget {
  const SelectChecklistView({super.key});
  @override
  State<SelectChecklistView> createState() => _SelectChecklistViewState();
}

class _SelectChecklistViewState extends State<SelectChecklistView> {
  final checklistController = ChecklistController.to;

  LocalSelectFilter get localSelectFilter =>
      LocalSearchController.to.localSelectFilter;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: LocalSearchController.to,
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
                  LocalSearchController.to.setSelectedLabelTitle(
                      LocalSearchController.to.checklistFilter, value);

                  setState(() {
                    localSelectFilter.checklist = value;
                  });
                });
          },
        ),
      ),
    );
  }
}
