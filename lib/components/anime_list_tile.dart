import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/models/anime.dart';

enum AnimeTileSubTitle { nameAnother, twoLinesOfInfo }

class AnimeListTile extends StatelessWidget {
  const AnimeListTile({
    Key? key,
    this.isThreeLine = false,
    required this.anime,
    this.animeTileSubTitle,
    this.showReviewNumber = false,
    this.showTrailingProgress = false,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  final bool isThreeLine;
  final Anime anime;
  final AnimeTileSubTitle? animeTileSubTitle;
  final bool showReviewNumber;
  final bool showTrailingProgress;
  final Widget? trailing;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      isThreeLine: isThreeLine,
      title: Text(
        anime.animeName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: () {
        switch (animeTileSubTitle) {
          case AnimeTileSubTitle.nameAnother:
            return anime.nameAnother.isNotEmpty
                ? Text(
                    anime.nameAnother,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : null;
          case AnimeTileSubTitle.twoLinesOfInfo:
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anime.getAnimeInfoFirstLine(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  anime.getAnimeInfoSecondLine(),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              ],
            );
          default:
            return null;
        }
      }(),
      leading: AnimeListCover(
        anime,
        showReviewNumber: showReviewNumber,
        reviewNumber: anime.reviewNumber,
      ),
      trailing: showTrailingProgress
          ? Text(
              "${anime.checkedEpisodeCnt}/${anime.animeEpisodeCnt}",
              style: Theme.of(context).textTheme.bodySmall,
            )
          : trailing,
      onTap: () {
        if (onTap != null) {
          onTap!();
        }
      },
    );
  }
}
