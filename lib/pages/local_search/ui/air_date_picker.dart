import 'package:flutter/material.dart';
import 'package:flutter_test_future/widgets/common_divider.dart';

class AirDatePicker extends StatefulWidget {
  const AirDatePicker(
      {this.initialYear,
      this.initialMonth,
      this.toggleable = false,
      this.onChanged,
      super.key});
  final int? initialYear;
  final int? initialMonth;
  final bool toggleable;
  final void Function(int? year, int? month)? onChanged;

  @override
  State<AirDatePicker> createState() => _AirDatePickerState();
}

class _AirDatePickerState extends State<AirDatePicker> {
  int maxYear = DateTime.now().year + 1;
  late int yearCount = maxYear - 1970 + 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        itemCount: yearCount,
        itemBuilder: (context, index) {
          final year = maxYear - index;
          return _buildYearAndMonth(year);
        },
        separatorBuilder: (BuildContext context, int index) =>
            const CommonDivider(),
      ),
    );
  }

  Container _buildYearAndMonth(int year) {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildYear(year),
          Row(
            children: List.generate(6, (index) => _buildMonth(year, index + 1)),
          ),
          Row(
            children: List.generate(6, (index) => _buildMonth(year, index + 7)),
          ),
        ],
      ),
    );
  }

  Container _buildYear(int year) {
    final selected = widget.initialYear == year && widget.initialMonth == null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () {
          if (widget.toggleable && selected) {
            widget.onChanged?.call(null, null);
          } else {
            widget.onChanged?.call(year, null);
          }
        },
        child: Container(
            decoration: BoxDecoration(
              color: selected ? Theme.of(context).primaryColor : null,
              borderRadius: BorderRadius.circular(99),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Text(
              '$year 年',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: selected ? Colors.white : null,
              ),
            )),
      ),
    );
  }

  _buildMonth(int year, int month) {
    final selected = widget.initialYear == year && widget.initialMonth == month;

    return Expanded(
      child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: () {
            if (widget.toggleable && selected) {
              widget.onChanged?.call(null, null);
            } else {
              widget.onChanged?.call(year, month);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: selected ? Theme.of(context).primaryColor : null,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Center(
              child: Text(
                '${month.toString().padLeft(2, '0')} 月',
                style: TextStyle(
                  fontSize: 14,
                  color: selected ? Colors.white : null,
                ),
              ),
            ),
          )),
    );
  }
}
