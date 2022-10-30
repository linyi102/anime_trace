import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

Widget buildWebSiteIcon(
    {required String url, required double size, bool addShadow = false}) {
  return Container(
      height: size,
      width: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size),
        child: url.startsWith("http")
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                // 占位符为透明图。否则显示先前缓存的图片时，不是圆形，加载完毕后又会显示圆形导致显得很突兀
                placeholder: (context, str) => Image.memory(kTransparentImage))
            : Image.asset(url, fit: BoxFit.cover),
      ),
      decoration: addShadow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(size),
              boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0.0, 15.0), //阴影xy轴偏移量
                      blurRadius: 15.0, //阴影模糊程度
                      spreadRadius: 1.0 //阴影扩散程度
                      )
                ])
          : null);
}
