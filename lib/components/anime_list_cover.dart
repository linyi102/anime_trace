import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';

import 'common_image.dart';

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
                  child: CommonImage(_anime.getCommonCoverUrl())),
            ),
            showReviewNumber && reviewNumber > 1
                ? Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      // height: 20,
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.orange,
                      ),
                      child: Text(
                        "$reviewNumber",
                        textScaleFactor: 0.8,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ));
  }
}
