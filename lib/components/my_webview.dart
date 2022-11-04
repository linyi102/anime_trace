import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 弃用
@Deprecated("推荐使用launchUrl，而不是WebView，因为太占存储空间了")
class MyWebView extends StatefulWidget {
  final String url;
  final String title;
  const MyWebView({Key? key, required this.url, this.title = ""})
      : super(key: key);

  @override
  State<MyWebView> createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            offset: const Offset(0, 50),
            itemBuilder: (popMenuContext) {
              return [
                // PopupMenuItem(
                //   padding: const EdgeInsets.all(0), // 变小
                //   child: ListTile(
                //     leading: const Icon(Icons.refresh),
                //     title: const Text("刷新"),
                //     style: ListTileStyle.drawer,
                //     onTap: () {
                //       Navigator.pop(popMenuContext);
                //     },
                //   ),
                // ),
                PopupMenuItem(
                  padding: const EdgeInsets.all(0), // 变小
                  child: ListTile(
                    leading: const Icon(Icons.copy),
                    title: const Text("复制链接"),
                    style: ListTileStyle.drawer,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.url));
                      Navigator.pop(popMenuContext);
                    },
                  ),
                ),
                PopupMenuItem(
                  padding: const EdgeInsets.all(0), // 变小
                  child: ListTile(
                    leading: const Icon(Icons.open_in_browser),
                    title: const Text("外部浏览器打开"),
                    style: ListTileStyle.drawer,
                    onTap: () {
                      Navigator.pop(popMenuContext);
                      LaunchUrlUtil.launch(
                          context: context, uriStr: widget.url, inApp: false);
                    },
                  ),
                ),
              ];
            },
          )
        ],
      ),
      body: WebView(
        initialUrl: widget.url,
        // 启用js，否则很多网页无法打开
        javascriptMode: JavascriptMode.unrestricted,
        // 只对ios有效
        // gestureNavigationEnabled: true,
      ),
    );
  }
}
