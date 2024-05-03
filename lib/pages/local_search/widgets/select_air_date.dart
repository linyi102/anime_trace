import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/local_search/controllers/local_search_controller.dart';
import 'package:flutter_test_future/pages/local_search/models/local_select_filter.dart';
import 'package:flutter_test_future/pages/local_search/ui/air_date_picker.dart';
import 'package:get/get.dart';

class SelectAirDateView extends StatefulWidget {
  const SelectAirDateView({required this.localSearchController, super.key});
  final LocalSearchController localSearchController;

  @override
  State<SelectAirDateView> createState() => _SelectAirDateViewState();
}

class _SelectAirDateViewState extends State<SelectAirDateView> {
  LocalSelectFilter get localSelectFilter =>
      widget.localSearchController.localSelectFilter;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: widget.localSearchController,
      tag: widget.localSearchController.tag,
      builder: (_) => Scaffold(
        body: AirDatePicker(
          initialYear: localSelectFilter.airDateYear,
          initialMonth: localSelectFilter.airDateMonth,
          toggleable: true,
          onChanged: (year, month) {
            widget.localSearchController.setAirDate(year, month);
          },
        ),
      ),
    );
  }
}
