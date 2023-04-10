import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/values/values.dart';

import 'common_image.dart';

// 列表样式时的动漫封面
class AnimeListCover extends StatelessWidget {
  final Anime _anime;
  final bool showReviewNumber;
  final int reviewNumber;
  final bool circular;

  const AnimeListCover(this._anime,
      {this.showReviewNumber = false,
      this.reviewNumber = 0,
      this.circular = false,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          circular ? EdgeInsets.zero : const EdgeInsets.fromLTRB(0, 5, 0, 5),
      child: Stack(
        children: [
          circular
              ? ClipOval(
                  child: SizedBox(
                    height: 40,
                    width: 40,
                    child: CommonImage(_anime.getCommonCoverUrl()),
                  ),
                )
              : AspectRatio(
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
                    padding: const EdgeInsets.fromLTRB(2, 1, 2, 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.stateRadius),
                      color: AppTheme.reviewNumberBg,
                    ),
                    child: Text(
                      "$reviewNumber",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.reviewNumberFg),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
