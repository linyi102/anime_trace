import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RouteUtil {
  static void getTo(dynamic page) {
    Get.to(page, transition: Transition.fadeIn);
  }

  static void materialTo(BuildContext context, Widget widget) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => widget,
        ));
  }
}
