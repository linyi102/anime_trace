import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

class WebSiteLogo extends StatelessWidget {
  final String url;
  final double size;
  final bool addShadow;
  const WebSiteLogo(
      {required this.url, required this.size, this.addShadow = false, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: size,
        width: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size),
          child: url.startsWith("http")
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  // 占位符为透明图。否则显示先前缓存的图片时，不是圆形，加载完毕后又会显示圆形导致显得很突兀
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Image.memory(kTransparentImage);
                  },
                  // 获取不到图片时，显示空Container
                  errorBuilder: (_, __, ___) => Container(),
                )
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
}
