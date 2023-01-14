import 'package:get/get.dart';

class GetRoute {
  static void to(dynamic page) {
    Get.to(page, transition: Transition.fadeIn);
  }
}
