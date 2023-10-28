import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({Key? key}) : super(key: key);
  @override
  State<VideoPlayerPage> createState() => VideoPlayerPageState();
}

class VideoPlayerPageState extends State<VideoPlayerPage> {
  late final player = Player();
  late final controller = VideoController(player);
  String title = '不死不幸 - 第 1 集';

  @override
  void initState() {
    super.initState();
    player.open(Media(
        'https://video.95189371.cn/5LiN5q275LiN6L+QX0VQMDEubXA0.mp3?verify=1698508094-O4Y717efbxWjLx%2FUoxVpAKkDISxgegp6wvIplKFm898%3D'));
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
            Positioned(
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
            ),
          ],
        ));
  }
}
