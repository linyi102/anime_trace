import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';

// 用于显示完整的动漫封面
class AnimeGridCover extends StatelessWidget {
  final Anime _anime;
  final bool showName;

  const AnimeGridCover(this._anime, {Key? key, this.showName = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
        ),
        child: AspectRatio(
          // 固定大小
          aspectRatio: 198 / 275,
          // aspectRatio: 31 / 45,
          // aspectRatio: 41 / 63,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                // 确保图片填充
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: _buildCover(),
                ),
                showName ? _buildBottomName() : Container()
              ],
            ),
          ),
        ));
  }

  _buildCover() {
    if (_anime.animeCoverUrl.isEmpty) {
      return Container(
        color: ThemeUtil.getAppBarBackgroundColor(),
        child: Center(
          child: Text(
            _anime.animeName.substring(
                0,
                _anime.animeName.length > 3 // 最低长度为3，此时下标最大为2，才可以设置end为3，[0, 3)
                    ? 3
                    : _anime.animeName.length), // 第二个参数如果只设置为3可能会导致越界
            textScaleFactor: 1.3,
            style: TextStyle(color: ThemeUtil.getFontColor()),
          ),
        ),
      );
    }

    // 网络封面
    if (_anime.animeCoverUrl.startsWith("http")) {
      return CachedNetworkImage(
        imageUrl: _anime.animeCoverUrl,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => const Placeholder(),
      );
    }

    // 本地封面
    return Image.file(
      File(ImageUtil.getAbsoluteCoverImagePath(_anime.animeCoverUrl)),
      fit: BoxFit.cover,
      // 这里不能使用errorImageBuilder，否则无法进入动漫封面详细页
      errorBuilder: (context, url, error) => const Placeholder(),
    );
  }

  _buildBottomName() {
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 80,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                    Colors.transparent,
                    Color.fromRGBO(0, 0, 0, 0.6)
                  ])),
            ),
          ],
        ),
        // 使用Align替换Positioned，可以保证在Stack下自适应父元素宽度
        Container(
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.only(bottom: 5),
          child: Container(
            // TODO 字体溢出，没有换行，可能是因为Stack，Container没有宽度限制
            padding: const EdgeInsets.fromLTRB(5, 0, 10, 5),
            child: Text(
              _anime.animeName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textScaleFactor: 0.9,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        )
      ],
    );
  }
}
