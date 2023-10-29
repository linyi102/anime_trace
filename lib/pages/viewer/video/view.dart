import 'package:flutter/material.dart';
import 'package:flutter_test_future/widgets/stack_appbar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({required this.url, this.title = '', Key? key})
      : super(key: key);
  final String url;
  final String title;

  @override
  State<VideoPlayerPage> createState() => VideoPlayerPageState();
}

class VideoPlayerPageState extends State<VideoPlayerPage> {
  late final player = Player();
  late final controller = VideoController(player);
  String get title => widget.title.isEmpty
      ? p.basenameWithoutExtension(widget.url)
      : widget.title;

  @override
  void initState() {
    super.initState();
    player.open(Media(widget.url));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      child: Scaffold(
          body: Stack(
        children: [
          Video(controller: controller),
          _buildAppBar(context),
        ],
      )),
    );
  }

  _buildAppBar(BuildContext context) {
    return StackAppBar(
      title: title,
    );
  }
}
