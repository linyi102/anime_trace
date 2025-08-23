// 本地笔记图片、本地封面、网络封面
import 'dart:io';

import 'package:animetrace/global.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/utils/extensions/color.dart';
import 'package:transparent_image/transparent_image.dart';

class CommonImage extends StatelessWidget {
  const CommonImage(this.url,
      {this.showIconWhenUrlIsEmptyOrError = true,
      this.reduceMemCache = true,
      this.memCacheWidth = 600,
      this.fit = BoxFit.cover,
      this.alignment = Alignment.center,
      Key? key})
      : super(key: key);
  final String url;
  final bool reduceMemCache;
  final int memCacheWidth;
  final bool showIconWhenUrlIsEmptyOrError; // 当没有图片或图片错误时，显示图标
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    Duration fadeInDuration = const Duration(milliseconds: 200);

    // 没有图片
    if (url.isEmpty) {
      return const _DefaultImage();
    }

    // 网络图片
    if (url.startsWith("http")) {
      return CacheNetworImage(
        url,
        headers:
            url.contains("douban") ? Global.getHeadersToGetDoubanPic() : null,
        fit: fit,
        alignment: alignment,
        cacheWidth: reduceMemCache ? memCacheWidth : null,
        fadeInDuration: fadeInDuration,
      );
    }

    // 本地图片
    File file = File(url);
    if (file.existsSync()) {
      // 如果存在该文件，才使用fileImage(否则FileImage里面会抛出找不到文件的异常，而且这里捕获不到)
      FileImage fileImage = FileImage(file);
      return Stack(
        fit: StackFit.expand,
        children: [
          const _DefaultImage(),
          FadeInImage(
            image: reduceMemCache
                ? ResizeImage(fileImage, width: memCacheWidth)
                    as ImageProvider<Object>
                : fileImage,
            fit: fit,
            alignment: alignment,
            fadeInDuration: fadeInDuration,
            placeholder: MemoryImage(kTransparentImage),
            imageErrorBuilder: (_, __, ___) => const _DefaultImage(),
          )
        ],
      );
    } else {
      return const _DefaultImage();
    }
  }
}

class _DefaultImage extends StatelessWidget {
  const _DefaultImage();

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: baseColor.withOpacityFactor(0.08),
          child: Center(
              child: Icon(
            // TODO 放大效果导致图标重复切换
            // isError ? Icons.broken_image : Icons.image,
            Icons.image,
            size: constraints.maxWidth < 50 ? 20 : 30,
            color: baseColor.withOpacityFactor(0.5),
          )),
        );
      },
    );
  }
}

class CacheNetworImage extends StatefulWidget {
  const CacheNetworImage(
    this.url, {
    super.key,
    this.fadeInDuration,
    this.cacheWidth,
    this.cacheHeight,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.headers,
  });
  final String url;
  final Duration? fadeInDuration;
  final int? cacheWidth;
  final int? cacheHeight;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final Map<String, String>? headers;

  @override
  State<CacheNetworImage> createState() => _CacheNetworImageState();
}

class _CacheNetworImageState extends State<CacheNetworImage>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    if (widget.fadeInDuration != null) {
      _controller =
          AnimationController(vsync: this, duration: widget.fadeInDuration);
      _animation = CurvedAnimation(parent: _controller!, curve: Curves.easeIn);
    }
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (_animation != null && !_animation!.isCompleted)
          const _DefaultImage(),
        ExtendedImage.network(
          widget.url,
          headers: widget.headers,
          cache: true,
          fit: widget.fit,
          alignment: widget.alignment,
          cacheWidth: widget.cacheWidth,
          cacheHeight: widget.cacheHeight,
          loadStateChanged: (state) {
            if (state.extendedImageLoadState == LoadState.completed) {
              if (state.wasSynchronouslyLoaded) return state.completedWidget;

              _controller?.forward();
              return _animation == null
                  ? state.completedWidget
                  : FadeTransition(
                      opacity: _animation!,
                      child: state.completedWidget,
                    );
            } else {
              // 这里使用占位图渐变效果不是很好，因为从default->image没有渐变，因此改用Stack
              return const SizedBox();
            }
          },
        ),
      ],
    );
  }
}
