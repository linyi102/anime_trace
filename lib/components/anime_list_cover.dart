import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/components/error_image_builder.dart';

import '../utils/image_util.dart';

// 列表样式时的动漫封面
class AnimeListCover extends StatelessWidget {
  final Anime _anime;
  final bool showReviewNumber;
  final int reviewNumber;

  const AnimeListCover(this._anime,
      {this.showReviewNumber = false, this.reviewNumber = 0, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1 / 1, // 正方形
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: _buildAnimeCover(),
              ),
            ),
            showReviewNumber && reviewNumber > 1
                ? Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      // height: 20,
                      padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.orange,
                      ),
                      child: Text(
                        " $reviewNumber ",
                        textScaleFactor: 0.8,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ));
  }

  _buildAnimeCover() {
    if (_anime.animeCoverUrl.isEmpty) return null;

    // 网络封面
    if (_anime.animeCoverUrl.startsWith("http")) {
      // 一定要缓存起来，否则断开网络后，无法显示图片
      // return Image.network(_anime.animeCoverUrl, fit: BoxFit.fitWidth);

      return CachedNetworkImage(
        imageUrl: _anime.animeCoverUrl,
        fit: BoxFit.fitWidth,
        errorWidget: (context, url, error) => const Placeholder(),
      );
    }

    // 本地封面
    return Image.file(
      File(ImageUtil.getAbsoluteCoverImagePath(_anime.animeCoverUrl)),
      fit: BoxFit.cover,
      errorBuilder: errorImageBuilder(_anime.animeCoverUrl),
    );
  }
}
