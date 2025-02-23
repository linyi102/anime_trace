import 'package:animetrace/models/week_record.dart';
import 'package:get/get.dart';

class WeeklyController extends GetxController {
  List<List<WeekRecord>> weeks = []; // 下标范围[0,6]，分别对应周一到周日

  int selectedWeekday = DateTime.now().weekday; // 默认选中当天，范围[1,7]

  @override
  void onInit() {
    super.onInit();
    for (int i = 0; i < 7; ++i) {
      weeks.add([]);
    }
  }

  void clearWeeks() {
    // 清空每天对应的数组，只留下weeks的六个空数组
    for (int i = 0; i < 7; ++i) {
      weeks[i].clear();
    }
  }
}
