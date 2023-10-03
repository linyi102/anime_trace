import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_image.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';
import 'package:flutter_test_future/pages/modules/note_img_viewer.dart';
import 'package:flutter_test_future/pages/settings/image_wall/style.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/values/values.dart';

class ImageWallPage extends StatefulWidget {
  const ImageWallPage({super.key, required this.imageUrls});
  final List<String> imageUrls;

  @override
  State<ImageWallPage> createState() => _ImageWallPageState();
}

class _ImageWallPageState extends State<ImageWallPage> {
  int groupCnt = NoteImageWallStyle.getGroupCnt();
  int get maxGroupCnt => 6;

  List<List<String>> groups = [];
  List<ScrollController> scrollControllers = [];
  List<Timer> timers = [];

  bool playing = false;
  int speed = 1; // 当前速度

  int get maxSpeed => 3; // 最大速度
  int get defaultSpaceMs => 6000; // 默认间隔
  int get spaceMs => defaultSpaceMs ~/ speed; // 当前间隔
  Duration get interval => Duration(milliseconds: spaceMs);

  double get groupSpacing => 5;
  double get imageSpacing => 4;
  late double imageHeight;
  double get imageWidth => imageHeight * 1.77;
  double get imageExtent => imageWidth + imageSpacing;

  bool get enableBlur => false;
  bool get autoToLandscape => false;

  @override
  void initState() {
    super.initState();
    Global.hideSystemUIOverlays();
    _loadGroup();

    // 切换为横屏
    // 由于会在切换前就准备好自动滚动，因此滚动速度会快一些，定时器触发后，才会根据横屏自动滚动，所以下次定时触发后会恢复正常速度
    // 解决方法是在切换完毕后再滚动
    if (autoToLandscape) {
      Global.toLandscape().then((value) {
        // 避免刚进入就滚动，来不及查看刚开始的图片
        // await Future.delayed(const Duration(seconds: 1));
        _play();
        // 若不进行重绘，不会触发PostFrameCallback导致不会自动滚动
        setState(() {});
      });
    } else {
      _play();
    }
  }

  @override
  void dispose() {
    _disposeGroup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    imageHeight = (MediaQuery.of(context).size.height -
            (Global.isPortrait(context) ? 200 : 100)) /
        (groupCnt + 1);

    return WillPopScope(
      onWillPop: () async {
        await _restoreDeviceUI();
        return true;
      },
      child: Theme(
        data: ThemeData.dark(useMaterial3: true)
            .copyWith(scaffoldBackgroundColor: Colors.black),
        child: Scaffold(
          body: Stack(
            children: [
              _buildGallery(),
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildAppBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildGallery() {
    return Column(
      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [for (var i = 0; i < groups.length; ++i) _buildGroup(i)],
    );
  }

  _buildAppBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              await _restoreDeviceUI();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          ),
          const Spacer(),
          _buildPlayControlButton(),
          _buildSpeedControlButton(),
          _buildGroupCntButton(),
          _buildShuffleButton(),
          if (Platform.isAndroid) _buildRotateScreenButton(),
        ],
      ),
    );
  }

  IconButton _buildGroupCntButton() {
    return IconButton(
      onPressed: () {
        showSelectGroupCntDialog();
      },
      icon: const Icon(Icons.table_rows, size: 20),
      // icon: Text('${groupCnt}r',
      //     style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Future<dynamic> showSelectGroupCntDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('选择行数'),
        content: SelectNumberPage(
            initialNumber: groupCnt,
            maxNumber: maxGroupCnt,
            onSelectedNumber: (number) {
              Navigator.pop(context);

              groupCnt = number;
              NoteImageWallStyle.setGroupCnt(number);
              // 取消定时器，避免旧的定时器仍然生效
              _pause();
              _loadGroup();
              _play();
            }),
      ),
    );
  }

  IconButton _buildRotateScreenButton() {
    return IconButton(
      onPressed: () async {
        await Global.switchDeviceOrientation(context);
        // 切换横竖屏后，重新滚动，避免仍然是切换前的速度
        _pauseAndPlay();
      },
      icon: const Icon(Icons.screen_rotation, size: 20),
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
      icon: const Icon(Icons.shuffle_rounded, size: 22),
    );
  }

  IconButton _buildPlayControlButton() {
    return IconButton(
      onPressed: _playOrPause,
      icon: Icon(playing
          ? Icons.pause_circle_outline_outlined
          : Icons.play_arrow_rounded),
    );
  }

  IconButton _buildSpeedControlButton() {
    return IconButton(
        onPressed: () {
          speed = speed % maxSpeed + 1;
          // 需要重新创建定时器
          _pauseAndPlay();
        },
        icon: Text(
          '${speed}x',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
  }

  _buildGroup(int groupIndex) {
    var group = groups[groupIndex];
    if (group.isEmpty) return const SizedBox();

    bool showDropShadow = groupIndex == groups.length - 1;

    return Container(
      height: showDropShadow ? imageHeight * 2 + 20 : imageHeight,
      margin: EdgeInsets.symmetric(vertical: groupSpacing),
      child: ListView.builder(
        // 播放时不允许手动滚动，暂停后支持滚动，并且可以查看图片
        // physics: playing ? const NeverScrollableScrollPhysics() : null,
        controller: scrollControllers[groupIndex],
        reverse: groupIndex % 2 == 1,
        scrollDirection: Axis.horizontal,
        itemExtent: imageExtent,
        itemBuilder: (context, index) {
          var imageUrl = group[index % group.length];

          var image = Container(
            height: imageHeight,
            width: imageWidth,
            margin: EdgeInsets.symmetric(horizontal: imageSpacing),
            // color: Colors.red,
            // child: Text(imageUrl),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.noteImgRadius),
                child: CommonImage(imageUrl)),
          );

          return Scrollbar(
            thumbVisibility: false,
            trackVisibility: false,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _toImageViewerPage(imageUrl),
                    child: image,
                  ),
                  if (showDropShadow) _buildDropShadowImage(image),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  _buildDropShadowImage(Container image) {
    return Container(
      padding: EdgeInsets.only(top: groupSpacing * 2),
      // 翻转
      child: Transform.flip(
        flipY: true,
        // 渐变
        child: ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black38, Colors.transparent])
              .createShader(Rect.fromLTRB(0, 0, rect.width, rect.height)),
          blendMode: BlendMode.dstIn,
          child: Stack(
            children: [
              image,
              // 模糊
              if (enableBlur)
                ClipRect(
                  child: BackdropFilter(
                    blendMode: BlendMode.srcIn,
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: SizedBox(height: imageHeight, width: imageWidth),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadGroup() {
    _disposeGroup();

    for (var i = 0; i < groupCnt; ++i) {
      groups.add([]);
      scrollControllers.add(ScrollController());
    }
    for (var i = 0; i < widget.imageUrls.length; ++i) {
      groups[i % groupCnt].add(widget.imageUrls[i]);
    }
    setState(() {});
  }

  void _disposeGroup() {
    for (var i = 0; i < scrollControllers.length; ++i) {
      scrollControllers[i].dispose();
    }
    scrollControllers.clear();
    groups.clear();
  }

  void _toImageViewerPage(String imageUrl) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewerPage(relativeLocalImages: [
            RelativeLocalImage(0, ImageUtil.getRelativeNoteImagePath(imageUrl))
          ]),
        ));
    // 返回后如果是播放状态，重新播放，避免过一会定时器触发后才继续自动播放
    _pauseAndPlay();
  }

  void _scrollOnceImage(ScrollController scrollController) {
    if (!scrollController.hasClients) return;

    scrollController.animateTo(
      scrollController.offset + imageExtent,
      duration: interval,
      curve: Curves.linear,
    );
  }

  void _playOrPause() {
    playing ? _pause() : _play();
  }

  void _pauseAndPlay() async {
    if (playing) {
      _pause();
      await Future.delayed(const Duration(milliseconds: 200));
      _play();
      if (mounted) setState(() {});
    }
  }

  void _play() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      timers.clear();

      for (var i = 0; i < scrollControllers.length; ++i) {
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

  void _pause() {
    for (var i = 0; i < scrollControllers.length; ++i) {
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

  /// 恢复屏幕方向和状态栏后再退出页面，避免退出时恢复突兀
  Future<void> _restoreDeviceUI() async {
    await Global.autoRotate();
    await Global.restoreSystemUIOverlays();
  }
}

class SelectNumberPage extends StatelessWidget {
  const SelectNumberPage({
    super.key,
    this.initialNumber = 1,
    required this.maxNumber,
    this.onSelectedNumber,
  });

  final int initialNumber;
  final int maxNumber;
  final void Function(int number)? onSelectedNumber;

  get radius => BorderRadius.circular(6);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(maxNumber, (index) {
              var number = index + 1;
              var isCur = initialNumber == number;

              return Container(
                margin: const EdgeInsets.all(4),
                child: InkWell(
                  borderRadius: radius,
                  onTap: () => onSelectedNumber?.call(number),
                  child: Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      color: isCur
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : null,
                      border: Border.all(
                          width: 0.6,
                          color: isCur
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).hintColor.withOpacity(0.1)),
                      borderRadius: radius,
                    ),
                    child: Center(
                        child: Text(
                      '$number',
                      style: isCur
                          ? TextStyle(color: Theme.of(context).primaryColor)
                          : null,
                    )),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
