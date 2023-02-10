import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/utils/time_show_util.dart';

/// 周日期栏
/// 不要转为无状态组件，因为要传入selectedWeekday，而它不是const，所以无法使用const WeeklyBar
/// 那么重新渲染时也会重新渲染WeeklyBar
class WeeklyBar extends StatefulWidget {
  const WeeklyBar({this.selectedWeekday = 1, this.onChanged, super.key});
  final int selectedWeekday;
  final void Function(int newWeekday)? onChanged;

  @override
  State<WeeklyBar> createState() => _WeeklyBarState();
}

class _WeeklyBarState extends State<WeeklyBar> {
  List<DateTime> weekDateTimes = [];
  late int selectedWeekday;
  final DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();

    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    Log.info("now: $now, monday: $monday");

    selectedWeekday = widget.selectedWeekday;
    for (int i = 0; i < 7; ++i) {
      weekDateTimes.add(monday.add(Duration(days: i)));
    }
  }

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);

    return Container(
      padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
      child: Row(
        children: weekDateTimes.map((dateTime) {
          // 周几
          int weekday = dateTime.weekday;
          // 是否被选中
          bool isSelected = dateTime.weekday == selectedWeekday;

          return Expanded(
            child: MaterialButton(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              onPressed: () {
                Log.info("点击weekday: $weekday");
                setState(() {
                  selectedWeekday = weekday;
                });
                if (widget.onChanged != null) {
                  widget.onChanged!(weekday);
                }
              },
              child: Column(
                children: [
                  // 显示周几
                  Text(TimeShowUtil.getChineseWeekdayByNumber(weekday),
                      style: const TextStyle(color: Colors.grey)),
                  // 显示日期
                  Container(
                    height: 24,
                    width: 24,
                    child: Center(
                        child: Text(
                      dateTime.day == now.day ? "今" : "${dateTime.day}",
                      style: TextStyle(color: isSelected ? Colors.white : null),
                    )),
                    decoration: isSelected
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            color: ThemeUtil.getPrimaryColor())
                        : const BoxDecoration(),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
