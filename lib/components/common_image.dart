// 本地笔记图片、本地封面、网络封面
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/global.dart';
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
    Duration fadeInDuration = const Duration(milliseconds: 400);

    // 没有图片
    if (url.isEmpty) {
      return _buildDefaultImage(context);
    }

    // 网络图片
    if (url.startsWith("http")) {
      // 断网后访问不了图片，所以使用CachedNetworkImage缓存起来
      return CachedNetworkImage(
        httpHeaders:
            url.contains("douban") ? Global.getHeadersToGetDoubanPic() : null,
        memCacheWidth: reduceMemCache ? memCacheWidth : null,
        imageUrl: url,
        fadeInDuration: fadeInDuration,
        errorWidget: (_, __, ___) => _buildDefaultImage(context, isError: true),
        placeholder: (_, __) => _buildDefaultImage(context),
        fit: fit,
        alignment: alignment,
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
          _buildDefaultImage(context),
          FadeInImage(
            image: reduceMemCache
                ? ResizeImage(fileImage, width: memCacheWidth)
                    as ImageProvider<Object>
                : fileImage,
            fit: fit,
            alignment: alignment,
            fadeInDuration: fadeInDuration,
            placeholder: MemoryImage(kTransparentImage),
            imageErrorBuilder: (_, __, ___) =>
                _buildDefaultImage(context, isError: true),
          )
        ],
      );
    } else {
      return _buildDefaultImage(context, isError: true);
    }
  }

  Widget _buildDefaultImage(
    context, {
    bool isError = false,
  }) {
    final baseColor = Theme.of(context).colorScheme.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: baseColor.withOpacityFactor(0.1),
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
