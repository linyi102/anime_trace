import 'package:flutter/material.dart';
import 'package:animetrace/global.dart';
import 'package:animetrace/pages/viewer/video/view.dart';
import 'package:animetrace/utils/platform.dart';
import 'package:animetrace/widgets/common_outlined_button.dart';
import 'package:animetrace/widgets/stack_appbar.dart';

class VideoPlayerWithLoadUrlPage extends StatefulWidget {
  const VideoPlayerWithLoadUrlPage(
      {required this.loadUrl,
      this.title = '',
      this.leading,
      this.whenDesktopToggleFullScreen,
      super.key});

  final Future<String> Function() loadUrl;
  final Widget? leading;
  final String title;
  final void Function(bool isFullScreen)? whenDesktopToggleFullScreen;

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
            widget.leading != null
                ? StackAppBar(leading: widget.leading)
                : StackAppBar(
                    onTapLeading: () async {
                      await Global.restoreDevice();
                      Navigator.pop(context);
                    },
                  ),
            _buildBody(),
            _buildParseHint()
          ],
        )),
      ),
    );
  }

  _buildParseHint() {
    return Positioned(
      left: 20,
      bottom: 20,
      child: Text(
        loading
            ? '解析链接中…'
            : error.isNotEmpty
                ? '解析链接失败 :('
                : '',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  _buildBody() {
    if (loading) {
      return const Align(
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (error.isNotEmpty) {
      return Align(
          alignment: Alignment.center,
          child: CommonOutlinedButton(onPressed: () => _loadUrl(), text: '重试'));
    }

    return VideoPlayerPage(
      url: url,
      title: widget.title,
      leading: widget.leading,
      whenDesktopToggleFullScreen: widget.whenDesktopToggleFullScreen,
    );
  }

  void _loadUrl() async {
    loading = true;
    error = '';
    if (mounted) setState(() {});

    url = await widget.loadUrl();
    if (url.isEmpty) {
      error = '解析链接失败 :(';
    }

    loading = false;
    if (mounted) setState(() {});
  }
}
