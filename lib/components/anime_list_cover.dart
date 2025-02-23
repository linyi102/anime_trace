import 'package:flutter/material.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/values/values.dart';

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
          SizedBox(
            height: 40,
            width: 40,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.imgRadius),
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
                    child: Center(
                      child: Text(
                        "$reviewNumber",
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.reviewNumberFg,
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
