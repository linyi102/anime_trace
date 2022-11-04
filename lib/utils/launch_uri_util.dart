import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../animation/fade_route.dart';
import '../components/my_webview.dart';

class LaunchUrlUtil {
  static launch(
      {required BuildContext context,
      required String uriStr,
      bool inApp = true}) async {
    if (uriStr.isEmpty) {
      showToast("无法访问空链接");
    } else if (inApp) {
      Navigator.push(
          context, FadeRoute(builder: (context) => MyWebView(url: uriStr)));
    } else {
      Uri uri = Uri.parse(uriStr);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        showToast("无法打开链接：$uri");
      }
      // if (!await launchUrl(uri,
      //     mode: inApp
      //         ? LaunchMode.inAppWebView
      //         : LaunchMode.externalApplication)) {
      //   showToast("无法打开链接：$uri");
      // }
    }
  }
}
