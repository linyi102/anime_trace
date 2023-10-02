import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_image.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';
import 'package:flutter_test_future/pages/modules/note_img_viewer.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/values/values.dart';

class ImageWallPage extends StatefulWidget {
  const ImageWallPage({super.key, required this.imageUrls});
  final List<String> imageUrls;

  @override
  State<ImageWallPage> createState() => _ImageWallPageState();
}

class _ImageWallPageState extends State<ImageWallPage> {
  int get groupCnt => 3;
  List<List<String>> groups = [];
  List<ScrollController> scrollControllers = [];
  List<Timer> timers = [];

  int speed = 1; // 当前速度
  int get maxSpeed => 3; // 最大速度
  int get standardSpaceMs => 3000; // 标准间隔为3s
  int get spaceMs => standardSpaceMs ~/ speed; // 当前间隔
  Duration get interval => Duration(milliseconds: spaceMs);
  bool playing = false;
  double get imageExtent => 160;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < groupCnt; ++i) {
      groups.add([]);
      scrollControllers.add(ScrollController());
    }
    for (var i = 0; i < widget.imageUrls.length; ++i) {
      groups[i % groupCnt].add(widget.imageUrls[i]);
    }
    _play();
  }

  @override
  void dispose() {
    for (var i = 0; i < groupCnt; ++i) {
      scrollControllers[i].dispose();
    }
    super.dispose();
  }

  _play() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      timers.clear();

      for (var i = 0; i < groupCnt; ++i) {
        var scrollController = scrollControllers[i];

        // 立即执行
        _scrollOnceImage(scrollController);
        // 再定时
        var timer = Timer.periodic(interval, (timer) {
          _scrollOnceImage(scrollController);
        });
        timers.add(timer);
      }
      if (mounted) {
        setState(() {
          playing = true;
        });
      }
    });
  }

  void _scrollOnceImage(ScrollController scrollController) {
    if (!scrollController.hasClients) return;

    scrollController.animateTo(
      scrollController.offset + imageExtent,
      duration: interval,
      curve: Curves.linear,
    );
  }

  _pause() {
    for (var i = 0; i < groupCnt; ++i) {
      var scrollController = scrollControllers[i];
      // 立即暂停
      scrollController.animateTo(scrollController.offset,
          duration: const Duration(milliseconds: 200), curve: Curves.linear);
      // 取消定时器
      timers[i].cancel();
    }
    if (mounted) {
      setState(() {
        playing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppBar(),
          Expanded(
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < groups.length; ++i) _buildGroup(i)
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildAppBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
        const Spacer(),
        _buildSpeedControlButton(),
        _buildPlayControlButton(),
        _buildShuffleButton(),
      ],
    );
  }

  IconButton _buildShuffleButton() {
    return IconButton(
      onPressed: () {
        for (var i = 0; i < groups.length; ++i) {
          groups[i].shuffle();
        }
        setState(() {});
      },
      icon: const Icon(Icons.shuffle_rounded),
    );
  }

  IconButton _buildPlayControlButton() {
    return IconButton(
      onPressed: () => playing ? _pause() : _play(),
      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
    );
  }

  IconButton _buildSpeedControlButton() {
    return IconButton(
        onPressed: () {
          _pause();
          speed = speed % maxSpeed + 1;
          // 需要重新创建定时器
          _play();
        },
        icon: Text('${speed}x'));
  }

  _buildGroup(int groupIndex) {
    var group = groups[groupIndex];
    if (group.isEmpty) return const SizedBox();

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListView.builder(
        controller: scrollControllers[groupIndex],
        reverse: groupIndex % 2 == 1,
        scrollDirection: Axis.horizontal,
        itemExtent: imageExtent,
        itemBuilder: (context, index) {
          var imageUrl = group[index % group.length];

          return GestureDetector(
            onTap: () {
              _toImageViewerPage(imageUrl);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              // color: Colors.red,
              // child: Text(imageUrl),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.noteImgRadius),
                  child: CommonImage(imageUrl)),
            ),
          );
        },
      ),
    );
  }

  void _toImageViewerPage(String imageUrl) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewerPage(relativeLocalImages: [
            RelativeLocalImage(0, ImageUtil.getRelativeNoteImagePath(imageUrl))
          ]),
        ));
  }
}
