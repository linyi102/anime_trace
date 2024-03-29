// 本地笔记图片、本地封面、网络封面
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test_future/global.dart';
import 'package:transparent_image/transparent_image.dart';

class CommonImage extends StatelessWidget {
  const CommonImage(this.url,
      {this.showIconWhenUrlIsEmptyOrError = true,
      this.reduceMemCache = true,
      this.memCacheWidth = 600,
      Key? key})
      : super(key: key);
  final String url;
  final bool reduceMemCache;
  final int memCacheWidth;
  final bool showIconWhenUrlIsEmptyOrError; // 当没有图片或图片错误时，显示图标

  @override
  Widget build(BuildContext context) {
    Duration fadeInDuration = const Duration(milliseconds: 400);

    // 没有图片
    if (url.isEmpty) {
      if (showIconWhenUrlIsEmptyOrError) {
        return Center(
            child: Image.asset("assets/icons/default_picture.png", width: 33));
      } else {
        return Image.memory(kTransparentImage);
      }
    }

    // 网络图片
    if (url.startsWith("http")) {
      // 断网后访问不了图片，所以使用CachedNetworkImage缓存起来
      return CachedNetworkImage(
        httpHeaders:
            url.contains("douban") ? Global.getHeadersToGetDoubanPic() : null,
        memCacheWidth: reduceMemCache ? memCacheWidth : null,
        imageUrl: url,
        errorWidget: (_, __, ___) => errorImageWidget(),
        fadeInDuration: fadeInDuration,
        // 未加载完图片时显示进度圈
        // placeholder: (_, __) => const LoadingWidget(center: true),
        fit: BoxFit.cover,
      );
    }

    // 本地图片
    File file = File(url);
    if (file.existsSync()) {
      // 如果存在该文件，才使用fileImage(否则FileImage里面会抛出找不到文件的异常，而且这里捕获不到)
      FileImage fileImage = FileImage(file);
      return FadeInImage(
        image: reduceMemCache
            ? ResizeImage(fileImage, width: memCacheWidth)
                as ImageProvider<Object>
            : fileImage,
        fit: BoxFit.cover,
        placeholder: MemoryImage(kTransparentImage),
        // placeholder: reduceMemCache
        //     ? MemoryImage(kTransparentImage)
        //     // 如果不压缩，则在加载原图时先显示压缩后的图片
        //     : ResizeImage(fileImage, width: memCacheWidth)
        //         as ImageProvider<Object>,
        // 去除占位图的渐变移除效果(为0会报错，而为1则会很快闪烁，所以都不行)
        // fadeOutDuration: const Duration(milliseconds: 1),
        fadeInDuration: fadeInDuration,
        imageErrorBuilder: (_, __, ___) => errorImageWidget(),
      );
    } else {
      return errorImageWidget();
    }
  }

  errorImageWidget() {
    if (showIconWhenUrlIsEmptyOrError) {
      return Center(
          child: Image.asset("assets/icons/failed_picture.png", width: 30));
    } else {
      return Image.memory(kTransparentImage);
    }
  }
}
