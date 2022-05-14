import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CountController extends GetxController {
  RxInt count = 0.obs;
  increment() {
    count++;
    debugPrint(count.toString());
  }
}
