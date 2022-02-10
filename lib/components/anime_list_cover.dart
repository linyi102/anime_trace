import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';

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
                child: _anime.animeCoverUrl.isEmpty
                    ? null
                    : CachedNetworkImage(
                        imageUrl: _anime.animeCoverUrl,
                        fit: BoxFit.fitWidth,
                      ),
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
                        color: Colors.blue,
                      ),
                      child: Text(
                        "$reviewNumber",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ));
  }
}
