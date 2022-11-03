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
    required bool isNoteImg}) {
  if (url.isEmpty) {
    // return const Center(child: Icon(Entypo.picture));
    return Center(
      child: Image.asset(
        "assets/icons/default_picture.png",
        // 默认宽度33(因为比较小，所以调大些)，失败宽度30
        width: 33,
        color: ThemeUtil.getCommonIconColor(),
      ),
    );
  }

  // 网络封面
  if (url.startsWith("http")) {
    // 断网后```访问不了图片，所以使用CachedNetworkImage缓存起来
    // return FadeInImage(
    //     placeholder: MemoryImage(kTransparentImage),
    //     fit: BoxFit.cover,
    //     image: NetworkImage(
    //       url,
    //     ));
    // 错误图片会返回404，报异常
    return CachedNetworkImage(
      // memCacheHeight: 500,
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget:
          errorImageBuilder(url: url, showErrorDialog: showErrorDialog),
    );
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
      fadeInDuration: const Duration(milliseconds: 100),
      imageErrorBuilder:
          errorImageBuilder(url: url, showErrorDialog: showErrorDialog),
    );
  } else {
    return errorImageWidget(url: url, showErrorDialog: showErrorDialog);
  }
}

/// 错误图片
Widget Function(dynamic buildContext, dynamic object, dynamic stackTrace)
    errorImageBuilder({required String url, required bool showErrorDialog}) {
  return (buildContext, object, stackTrace) {
    // return const Center(child: Icon(Icons.broken_image));
    return errorImageWidget(url: url, showErrorDialog: showErrorDialog);
  };
}

Widget errorImageWidget({required String url, required bool showErrorDialog}) {
  return Center(
    child: Image.asset(
      "assets/icons/failed_picture.png",
      width: 30,
      color: ThemeUtil.getCommonIconColor(),
    ),
  );
}
