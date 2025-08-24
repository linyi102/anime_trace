import 'package:animetrace/models/week_record.dart';
import 'package:flutter/material.dart';

class WeeklyController extends ChangeNotifier {
  /// 下标范围[0,6]，分别对应周一到周日
  List<List<WeekRecord>> weeks = List.generate(7, (index) => []);

  /// 默认选中当天，范围[1,7]
  int _selectedWeekday = DateTime.now().weekday;

  int get selectedWeekday => _selectedWeekday;

  set selectedWeekday(int newWeekday) {
    assert(1 <= newWeekday && newWeekday <= 7);
    _selectedWeekday = newWeekday;
    notifyListeners();
  }

  void clearWeeks() {
    // 清空每天对应的数组，只留下weeks的六个空数组
    for (int i = 0; i < 7; ++i) {
      weeks[i].clear();
    }
  }
}
