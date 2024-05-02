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
  int curYear = DateTime.now().year;
  late int yearCount = curYear - 1970 + 1;
  LocalSelectFilter get localSelectFilter =>
      widget.localSearchController.localSelectFilter;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: widget.localSearchController,
      builder: (_) => Scaffold(
        body: AirDatePicker(
          initialYear: localSelectFilter.airDateYear,
          initialMonth: localSelectFilter.airDateMonth,
          toggleable: true,
          onChanged: (year, month) {
            final selectedLabel = () {
              if (year == null && month == null) return null;
              if (year != null && month == null) return '$year';
              return '$year-${month.toString().padLeft(2, '0')}';
            }();

            setState(() {
              localSelectFilter.airDateYear = year;
              localSelectFilter.airDateMonth = month;
            });
            widget.localSearchController.setSelectedLabelTitle(
                widget.localSearchController.airDateFilter, selectedLabel);
          },
        ),
      ),
    );
  }
}
