import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/enum/anime_category.dart';
import 'package:flutter_test_future/pages/local_search/controllers/local_search_controller.dart';
import 'package:flutter_test_future/pages/local_search/models/local_select_filter.dart';
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
      builder: (_) => Scaffold(
        body: ListView.builder(
          itemCount: AnimeCategory.values.length,
          itemBuilder: (context, index) {
            final category = AnimeCategory.values[index];
            return RadioListTile<AnimeCategory>(
                title: Text(category.label),
                toggleable: true,
                value: category,
                groupValue: localSelectFilter.category,
                onChanged: (value) {
                  widget.localSearchController.setSelectedLabelTitle(
                      widget.localSearchController.categoryFilter,
                      value?.label);

                  setState(() {
                    localSelectFilter.category = value;
                  });
                });
          },
        ),
      ),
    );
  }
}
