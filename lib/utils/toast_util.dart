import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';

class ToastUtil {
  static showText(String msg) {
    BotToast.showCustomText(
      onlyOne: true,
      animationDuration: const Duration(milliseconds: 100),
      animationReverseDuration: const Duration(milliseconds: 100),
      toastBuilder: (cancelFunc) => Card(
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
          child: Text(
            msg,
            style: TextStyle(
              fontFamily: 'invalid',
              fontSize: 13,
              fontFamilyFallback: ThemeController.to.fontFamilyFallback,
            ),
          ),
        ),
      ),
    );
  }
}
