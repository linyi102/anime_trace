// 本地笔记图片、本地封面、网络封面
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:transparent_image/transparent_image.dart';

import '../utils/theme_util.dart';

class CommonImage extends StatelessWidget {
  const CommonImage(this.url,
      {this.showIconWhenUrlIsEmptyOrError = true,
      this.reduceMemCache = true,
      this.memCacheWidth = 400,
      Key? key})
      : super(key: key);
  final String url;
  final bool reduceMemCache;
  final int memCacheWidth;
  final bool showIconWhenUrlIsEmptyOrError; // 当没有图片或图片错误时，显示图标

  @override
  Widget build(BuildContext context) {
    Color imgIconColor = ThemeUtil.getCommonIconColor();
    Duration fadeInDuration = const Duration(milliseconds: 200);

    // 没有图片
    if (url.isEmpty) {
      if (showIconWhenUrlIsEmptyOrError) {
        return Center(
            child: Image.asset("assets/icons/default_picture.png",
                width: 33, color: imgIconColor));
      } else {
        return Image.memory(kTransparentImage);
      }
    }

    // 网络图片
    if (url.startsWith("http")) {
      // 断网后访问不了图片，所以使用CachedNetworkImage缓存起来
      return CachedNetworkImage(
        memCacheWidth: reduceMemCache ? memCacheWidth : null,
        imageUrl: url,
        errorWidget: (_, __, ___) => errorImageWidget(),
        fadeInDuration: fadeInDuration,
        // placeholder: reduceMemCache
        //     ? null
        //     // 如果不压缩，则在加载原图时先显示压缩后的图片
        //     // 会闪烁，效果不好
        //     : (context, url) => CachedNetworkImage(
        //           memCacheWidth: memCacheWidth,
        //           fadeInDuration: fadeInDuration,
        //           fadeOutDuration: Duration.zero,
        //           imageUrl: url,
        //           fit: BoxFit.cover,
        //         ),

        // 未加载完图片时显示进度圈
        // placeholder: (_, __) => const Center(child: SizedBox(
        //     height: 20,
        //     width: 20,
        //     child: CircularProgressIndicator())),
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
          child: Image.asset("assets/icons/failed_picture.png",
              width: 30, color: ThemeUtil.getCommonIconColor()));
    } else {
      return Image.memory(kTransparentImage);
    }
  }
}
