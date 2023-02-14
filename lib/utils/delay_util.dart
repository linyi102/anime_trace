import 'dart:async';

class DelayUtil {
  static Timer? timer;

  static const enableDelay = false;

  /// 延时搜索
  static delaySearch(
    Function doSomething, {
    Duration duration = const Duration(milliseconds: 500),
  }) {
    if (enableDelay) {
      // 如果之前在计时了，则取消掉
      timer?.cancel();
      // 重新定时
      timer = Timer(duration, () {
        doSomething();
        timer = null;
      });
    } else {
      // 不开启延时
      doSomething();
    }
  }
}
