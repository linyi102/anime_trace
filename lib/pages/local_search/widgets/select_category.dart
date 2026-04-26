import 'package:animetrace/controllers/category_controller.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/pages/local_search/controllers/local_search_controller.dart';
import 'package:animetrace/pages/local_search/models/local_select_filter.dart';
import 'package:get/get.dart';

class SelectCategoryView extends StatefulWidget {
  const SelectCategoryView({required this.localSearchController, super.key});
  final LocalSearchController localSearchController;

  @override
  State<SelectCategoryView> createState() => _SelectCategoryViewState();
}

class _SelectCategoryViewState extends State<SelectCategoryView> {
  LocalSelectFilter get localSelectFilter =>
      widget.localSearchController.localSelectFilter;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: widget.localSearchController,
      tag: widget.localSearchController.tag,
      builder: (_) => Scaffold(
        body: ListView.builder(
          itemCount: CategoryController.to.categories.length,
          itemBuilder: (context, index) {
            final category = CategoryController.to.categories[index];
            return RadioListTile<String>(
                title: Text(category),
                toggleable: true,
                value: category,
                groupValue: localSelectFilter.category,
                onChanged: (value) {
                  widget.localSearchController.setCategory(value);
                });
          },
        ),
      ),
    );
  }
}
