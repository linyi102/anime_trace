import 'package:oktoast/oktoast.dart';
import 'package:url_launcher/url_launcher.dart';

class LaunchUrlUtil {
  static launch(String uriStr, {bool inApp = false}) async {
    if (uriStr.isEmpty) showToast("无法访问空链接");

    Uri uri = Uri.parse(uriStr);
    if (!await launchUrl(uri,
        mode:
            inApp ? LaunchMode.inAppWebView : LaunchMode.externalApplication)) {
      showToast("无法打开链接：$uri");
    }
  }
}
