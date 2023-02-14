import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';

class CommonUtil {
  static copyContent(String text,
      {bool toast = true, String toastMsg = "已复制到剪贴板"}) {
    Clipboard.setData(ClipboardData(text: text));
    if (toast) showToast(toastMsg);
  }
}
