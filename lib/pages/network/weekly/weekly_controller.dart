import 'package:flutter_test_future/models/week_record.dart';
import 'package:get/get.dart';

class WeeklyController extends GetxController {
  List<List<WeekRecord>> weeks = []; // 下标范围[0,6]，分别对应周一到周日
}
