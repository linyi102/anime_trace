import 'package:animetrace/utils/log.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/components/loading_dialog.dart';
import 'package:animetrace/controllers/theme_controller.dart';
import 'package:get/get.dart';

class ToastUtil {
  /// 对话框
  /// 优点：
  ///   不用context
  ///   样式会跟着主题变化
  /// 缺点：
  ///   没有返回值
  static showDialog({
    required Widget Function(void Function() close) builder,
    bool clickClose = true,
  }) {
    Get.dialog(
      PopScope(
        child: builder(Get.back),
        canPop: clickClose,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          // 如果允许点击对话框外区域，或点击虚拟返回键关闭对话框，则执行关闭
          if (clickClose) Get.back();
        },
      ),
      barrierDismissible: clickClose,
    );
  }

  static void Function() showLoading<R>({
    String msg = '加载中',
    Future<R> Function()? task,
    void Function(R taskValue)? onTaskSuccess,
    void Function(Object e)? onTaskError,
    void Function()? onTaskComplete,
    bool clickClose = true,
  }) {
    return BotToast.showCustomLoading(
      toastBuilder: (void Function() cancel) {
        if (task == null) {
          return LoadingDialog(msg);
        }

        _doTask(task, onTaskSuccess, onTaskError, onTaskComplete, cancel);
        return LoadingDialog(msg);
      },
      clickClose: clickClose,
    );
  }

  static void _doTask<R>(
      Future<R> Function() task,
      void Function(R taskValue)? onTaskSuccess,
      void Function(Object e)? onTaskError,
      void Function()? onTaskComplete,
      void Function() cancel) async {
    try {
      final value = (await Future.wait([
        task(),
        Future.delayed(const Duration(milliseconds: 500)),
      ]))
          .first;

      onTaskSuccess?.call(value);
    } catch (e) {
      AppLog.error('toast loading task error：$e');
      onTaskError?.call(e);
    } finally {
      onTaskComplete?.call();
      cancel();
    }
  }

  static showText(String msg) {
    BotToast.showCustomText(
      onlyOne: true,
      animationDuration: const Duration(milliseconds: 100),
      animationReverseDuration: const Duration(milliseconds: 100),
      toastBuilder: (cancelFunc) => Card(
        elevation: 12,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
