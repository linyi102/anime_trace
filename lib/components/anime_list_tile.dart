import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/theme_util.dart';

enum AnimeTileSubTitle { nameAnother, twoLinesOfInfo }

class AnimeListTile extends StatelessWidget {
  const AnimeListTile({
    Key? key,
    this.isThreeLine = false,
    required this.anime,
    this.animeTileSubTitle,
    this.showReviewNumber = false,
    this.showTrailingProgress = false,
    this.onTap,
  }) : super(key: key);

  final bool isThreeLine;
  final Anime anime;
  final AnimeTileSubTitle? animeTileSubTitle;
  final bool showReviewNumber;
  final bool showTrailingProgress;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      isThreeLine: isThreeLine,
      title: Text(
        anime.animeName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: () {
        double textScaleFactor = ThemeUtil.tinyScaleFactor;
        switch (animeTileSubTitle) {
          case AnimeTileSubTitle.nameAnother:
            return anime.nameAnother.isNotEmpty
                ? Text(anime.nameAnother,
                    textScaleFactor: textScaleFactor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)
                : null;
          case AnimeTileSubTitle.twoLinesOfInfo:
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(anime.getAnimeInfoFirstLine(),
                    textScaleFactor: textScaleFactor),
                Text(anime.getAnimeInfoSecondLine(),
                    textScaleFactor: textScaleFactor)
              ],
            );
          default:
            return null;
        }
      }(),
      leading: showReviewNumber
          ? AnimeListCover(
              anime,
              showReviewNumber: showReviewNumber,
              reviewNumber: anime.reviewNumber,
            )
          : AnimeGridCover(
              anime,
              onlyShowCover: true,
            ),
      trailing: showTrailingProgress
          ? Text("${anime.checkedEpisodeCnt}/${anime.animeEpisodeCnt}",
              textScaleFactor: 0.9)
          : null,
      onTap: () {
        if (onTap != null) {
          onTap!();
        }
      },
    );
  }
}
