import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_dialog.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';

class ToastUtil {
  static showDialog(
      {required Widget Function(void Function() cancel) builder}) {
    BotToast.showCustomLoading(
      animationDuration: const Duration(milliseconds: 200),
      animationReverseDuration: const Duration(milliseconds: 200),
      clickClose: true,
      toastBuilder: builder,
    );
  }

  static showLoading({
    String msg = "加载中",
    bool clickClose = true,
    Future<dynamic> Function()? task,
    Function(dynamic taskValue)? onTaskComplete,
  }) {
    BotToast.showCustomLoading(
      toastBuilder: (void Function() cancelFunc) {
        if (task == null) {
          // 没有任务的话，等待1s后结束
          Future.delayed(const Duration(seconds: 1), () {
            cancelFunc.call();
          });
        } else {
          task().then((value) {
            // 关闭加载框
            cancelFunc.call();
            // 回调
            if (onTaskComplete != null) onTaskComplete(value);
          });
        }

        return LoadingDialog(msg);
      },
      clickClose: clickClose,
    );
  }

  static showText(String msg) {
    BotToast.showCustomText(
      onlyOne: true,
      animationDuration: const Duration(milliseconds: 100),
      animationReverseDuration: const Duration(milliseconds: 100),
      toastBuilder: (cancelFunc) => Card(
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
