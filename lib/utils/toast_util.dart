import 'package:animetrace/models/params/result.dart';
import 'package:animetrace/utils/log.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/components/loading_dialog.dart';
import 'package:animetrace/controllers/theme_controller.dart';

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
    BotToast.showCustomLoading(
      animationDuration: const Duration(milliseconds: 200),
      animationReverseDuration: const Duration(milliseconds: 200),
      clickClose: clickClose,
      toastBuilder: (cancelFunc) {
        return WillPopScope(
          child: builder(cancelFunc),
          onWillPop: () async {
            // 如果允许点击对话框外区域，或点击虚拟返回键关闭对话框，则执行关闭
            if (clickClose) cancelFunc();
            // 始终返回false，避免退出页面
            return false;
          },
        );
      },
    );
  }

  static void Function() showLoading({
    String msg = "加载中",
    bool clickClose = true,
    Future<dynamic> Function()? task,
    Function(dynamic taskValue)? onTaskComplete,
  }) {
    return BotToast.showCustomLoading(
      toastBuilder: (void Function() cancelFunc) {
        if (task == null) {
          return LoadingDialog(msg);
        }

        doTask(
          task: task,
          onTaskComplete: onTaskComplete,
          cancelFunc: cancelFunc,
        );
        return LoadingDialog(msg);
      },
      clickClose: clickClose,
    );
  }

  static doTask({
    required Future<dynamic> Function() task,
    Function(dynamic taskValue)? onTaskComplete,
    required void Function() cancelFunc,
  }) async {
    final start = DateTime.now();
    try {
      final taskValue = await task();
      final end = DateTime.now();
      if (end.difference(start).inMilliseconds < 300) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      onTaskComplete?.call(taskValue);
    } catch (e, st) {
      logger.error('Toast Loading doTask error', error: e, stackTrace: st);
      onTaskComplete?.call(Result.failure(-1, '任务执行失败'));
    } finally {
      // 关闭加载框
      cancelFunc();
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
