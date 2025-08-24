import 'package:animetrace/pages/network/weekly/weekly_controller.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/time_util.dart';

/// 周日期栏
/// 不要转为无状态组件，因为要传入selectedWeekday，而它不是const，所以无法使用const WeeklyBar
/// 那么重新渲染时也会重新渲染WeeklyBar
class WeeklyBar extends StatefulWidget {
  const WeeklyBar({
    super.key,
    required this.controller,
    this.onChanged,
  });
  final WeeklyController controller;
  final void Function(int newWeekday)? onChanged;

  @override
  State<WeeklyBar> createState() => _WeeklyBarState();
}

class _WeeklyBarState extends State<WeeklyBar> {
  List<DateTime> weekDateTimes = [];
  final DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();

    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    Log.info("now: $now, monday: $monday");

    weekDateTimes =
        List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) => Row(
          children: weekDateTimes.map((dateTime) {
            // 周几
            int weekday = dateTime.weekday;
            // 是否被选中
            bool isSelected =
                dateTime.weekday == widget.controller.selectedWeekday;

            return Expanded(
              child: InkWell(
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: () {
                  Log.info("点击weekday: $weekday");
                  widget.controller.selectedWeekday = weekday;
                  widget.onChanged?.call(weekday);
                },
                child: Column(
                  children: [
                    // 显示周几
                    Text(TimeUtil.getChineseWeekdayByNumber(weekday),
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 5),
                    // 显示日期
                    Container(
                      height: 24,
                      width: 24,
                      child: Center(
                          child: Text(
                        dateTime.day == now.day ? "今" : "${dateTime.day}",
                        style: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontSize: 12),
                      )),
                      decoration: isSelected
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary)
                          : const BoxDecoration(),
                    )
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
