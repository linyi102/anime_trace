import 'dart:math';

import 'package:get/get.dart';
import 'package:animetrace/utils/log.dart';

class CountController extends GetxController {
  RxInt count = 0.obs;

  increment() async {
    // count++; // 可以
    // count = Random().nextInt(100).obs; // 无法实时看到变化
    // count.value = Random().nextInt(100); // 可以
    // count = (await getCount()).obs; // 无法实时看到变化
    count.value = await getCount(); // 可以
    Log.info(count.toString());
  }

  Future<int> getCount() async {
    return Random().nextInt(100);
  }
}
