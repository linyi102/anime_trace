import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:url_launcher/url_launcher.dart';

class LaunchUrlUtil {
  static launch(
      {required BuildContext context,
      required String uriStr,
      bool inApp = false}) async {
    if (uriStr.isEmpty) {
      showToast("无法访问空链接");
    }
    // else if (inApp && Platform.isAndroid) {
    //   // 只有安卓才允许打开webview界面
    //   // 太占空间了，尤其是语雀，占了300多兆，还在用户数据，不在缓存
    //   Navigator.push(
    //       context, MaterialPageRoute(builder: (context) => MyWebView(url: uriStr)));
    // }
    else {
      // 数据也会放在用户数据，而非缓存，所以尽量都以浏览器方式打开
      if (!await launchUrl(Uri.parse(uriStr),
          mode: inApp
              ? LaunchMode.inAppWebView
              : LaunchMode.externalApplication)) {
        showToast("无法打开链接：$uriStr");
      }
    }
  }
}
