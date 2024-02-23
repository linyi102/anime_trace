import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RouteUtil {
  static void getTo(dynamic page) {
    Get.to(page, transition: Transition.fadeIn);
  }

  static Future<T?> materialTo<T extends Object?>(
      BuildContext context, Widget widget) {
    return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => widget,
        ));
  }
}
