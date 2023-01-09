import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:transparent_image/transparent_image.dart';

import '../utils/image_util.dart';

/// 本地笔记图片和封面的相对地址、网络封面
Widget buildImgWidget(
    {required String url,
    required bool showErrorDialog,
    required bool isNoteImg,
    Color? color}) {
  color = color ?? ThemeUtil.getCommonIconColor();
  if (url.isEmpty) {
    // return const Center(child: Icon(Entypo.picture));
    return Center(
      child: Image.asset(
        "assets/icons/default_picture.png",
        // 默认宽度33(因为比较小，所以调大些)，失败宽度30
        width: 33,
        color: color,
      ),
    );
  }

  // 网络封面
  if (url.startsWith("http")) {
    // 断网后访问不了图片，所以使用CachedNetworkImage缓存起来
    return getNetWorkImage(url,
        errorWidget: errorImageBuilder(
            url: url, showErrorDialog: showErrorDialog, color: color));
  }

  // 因为封面和笔记图片文件的目录不一样，所以两个都要设置
  // 增加过渡效果，否则突然显示会很突兀
  // final LocalImgDirController localImgDirController = Get.find();
  File file = File(isNoteImg
      ? ImageUtil.getAbsoluteNoteImagePath(url)
      : ImageUtil.getAbsoluteCoverImagePath(url));
  // 如果存在该文件，才使用fileImage(否则FileImage里面会抛出找不到文件的异常，而且这里捕获不到)
  if (file.existsSync()) {
    return FadeInImage(
      placeholder: MemoryImage(kTransparentImage),
      image: FileImage(file),
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 500),
      // CachedNetworkImage也是500
      imageErrorBuilder: errorImageBuilder(
          url: url, showErrorDialog: showErrorDialog, color: color),
    );
  } else {
    return errorImageWidget(
        url: url, showErrorDialog: showErrorDialog, color: color);
  }
}

/// 访问网络图片，遇到404避免报异常
/// 虽然动漫收藏页不报错了，但一进入详细页就会报错，很奇怪
Widget getNetWorkImage(String url,
    {
    // Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
    Widget Function(BuildContext, String, dynamic)? errorWidget,
    Color? color,
    BlendMode? colorBlendMode}) {
  return CachedNetworkImage(
    imageUrl: url,
    errorWidget: errorWidget,
    // 未加载完图片时显示进度圈
    // placeholder: (_, __) => const Center(child: SizedBox(
    //     height: 20,
    //     width: 20,
    //     child: CircularProgressIndicator())),
    fit: BoxFit.cover,
    color: color,
    colorBlendMode: colorBlendMode,
  );
  // FadeInImage image = FadeInImage(
  //   image: CachedNetworkImageProvider(url),
  //   placeholder: MemoryImage(kTransparentImage),
  //   imageErrorBuilder: errorBuilder,
  //   fit: BoxFit.cover,
  //   // 没有color和colorBlendMode
  // );

  // 没有过渡效果
  // Image image = Image(
  //   image: CachedNetworkImageProvider(url),
  //   errorBuilder: errorBuilder,
  //   fit: BoxFit.cover,
  //   color: color,
  //   colorBlendMode: colorBlendMode,
  // );

  // final ImageStream imageStream = image.image.resolve(ImageConfiguration.empty);
  // imageStream.addListener(ImageStreamListener((image, synchronousCall) {},
  //     onError: (Object ob, StackTrace? st) {
  //       // Log.error("访问网络图片失败：$url");
  //     }));
  // return image;
}

/// 错误图片
Widget Function(dynamic buildContext, dynamic object, dynamic stackTrace)
    errorImageBuilder(
        {required String url, required bool showErrorDialog, Color? color}) {
  return (buildContext, object, stackTrace) {
    // return const Center(child: Icon(Icons.broken_image));
    return errorImageWidget(
        url: url, showErrorDialog: showErrorDialog, color: color);
  };
}

Widget errorImageWidget(
    {required String url, required bool showErrorDialog, Color? color}) {
  return Center(
    child: Image.asset(
      "assets/icons/failed_picture.png",
      width: 30,
      color: color ?? ThemeUtil.getCommonIconColor(),
    ),
  );
}
