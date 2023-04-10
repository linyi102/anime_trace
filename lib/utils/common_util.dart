import 'package:flutter/services.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

class CommonUtil {
  static copyContent(String text,
      {bool toast = true,
      String successMsg = "已复制到剪切板",
      String errorMsg = "内容为空，无法复制"}) {
    if (text.isEmpty) {
      ToastUtil.showText(errorMsg);
      return;
    }

    Clipboard.setData(ClipboardData(text: text));
    if (toast) ToastUtil.showText(successMsg);
  }
}
