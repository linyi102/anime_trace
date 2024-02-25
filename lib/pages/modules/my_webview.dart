import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/common_util.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:webview_flutter/webview_flutter.dart';

@Deprecated("WebView占用手机存储空间太高，推荐使用launchUrl")
class MyWebView extends StatefulWidget {
  final String url;
  final String title;
  const MyWebView({Key? key, required this.url, this.title = ""})
      : super(key: key);

  @override
  State<MyWebView> createState() => _MyWebViewState();
}

// ignore: deprecated_member_use_from_same_package
class _MyWebViewState extends State<MyWebView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton(
            position: PopupMenuPosition.under,
            icon: const Icon(Icons.more_vert),
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
                      CommonUtil.copyContent(widget.url);
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
