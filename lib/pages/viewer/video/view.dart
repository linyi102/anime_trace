import 'package:flutter/material.dart';
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
    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Video(controller: controller),
            _buildAppBar(context),
          ],
        ));
  }

  _buildAppBar(BuildContext context) {
    return Positioned(
      top: 15,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Row(
          children: [
            const SizedBox(width: 5),
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios_new_outlined),
              color: Colors.white,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    overflow: TextOverflow.ellipsis),
              ),
            ),
            // IconButton(
            //     onPressed: () {},
            //     icon: const Icon(Icons.more_vert, color: Colors.white))
          ],
        ),
      ),
    );
  }
}
