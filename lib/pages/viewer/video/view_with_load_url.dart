import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/pages/viewer/video/view.dart';
import 'package:flutter_test_future/utils/platform.dart';
import 'package:flutter_test_future/widgets/stack_appbar.dart';

class VideoPlayerWithLoadUrlPage extends StatefulWidget {
  const VideoPlayerWithLoadUrlPage(
      {required this.loadUrl, this.title = '', super.key});

  final Future<String> Function() loadUrl;
  final String title;

  @override
  State<VideoPlayerWithLoadUrlPage> createState() =>
      _VideoPlayerWithLoadUrlPageState();
}

class _VideoPlayerWithLoadUrlPageState
    extends State<VideoPlayerWithLoadUrlPage> {
  bool loading = false;
  String error = '';
  late String url;

  @override
  void initState() {
    super.initState();

    _loadUrl();

    if (PlatformUtil.isMobile) {
      Global.toLandscape();
      Global.hideSystemUIOverlays();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await Global.restoreDevice();
        return true;
      },
      child: Theme(
        data: Theme.of(context).copyWith(scaffoldBackgroundColor: Colors.black),
        child: Scaffold(
            body: Stack(
          children: [
            StackAppBar(
              onTapLeading: () async {
                await Global.restoreDevice();
                Navigator.pop(context);
              },
            ),
            _buildBody(),
          ],
        )),
      ),
    );
  }

  _buildBody() {
    if (loading) {
      return const Align(
        alignment: Alignment.center,
        child: LoadingWidget(text: '正在解析视频链接…', textColor: Colors.white),
      );
    }

    if (error.isNotEmpty) {
      return Align(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, style: const TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    return VideoPlayerPage(url: url, title: widget.title);
  }

  void _loadUrl() async {
    loading = true;
    if (mounted) setState(() {});

    url = await widget.loadUrl();
    if (url.isEmpty) {
      error = '很抱歉，无法获取到播放链接';
    }

    loading = false;
    if (mounted) setState(() {});
  }
}
