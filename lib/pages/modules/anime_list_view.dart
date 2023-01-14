import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../../components/anime_grid_cover.dart';
import '../../components/anime_list_cover.dart';
import '../../models/anime.dart';
import '../../utils/sp_util.dart';
import '../../utils/theme_util.dart';

enum AnimeTileSubTitle { nameAnother, twoLinesOfInfo }

/// 动漫列表视图
/// 不适合分页加载
class AnimeListView extends StatelessWidget {
  const AnimeListView(
      {required this.animes,
      this.animeTileSubTitle,
      this.isThreeLine = false,
      this.showTrailingProgress = false,
      this.showReviewNumber = false,
      this.shrinkWrapAndNeverScroll = false,
      this.onClick,
      Key? key})
      : super(key: key);
  final List<Anime> animes;
  final AnimeTileSubTitle? animeTileSubTitle; // 指定副标题显示什么信息
  final bool isThreeLine; // 是否高度变高
  final bool showTrailingProgress; // 尾部是否显示进度
  final bool showReviewNumber; // 显示观看序号
  final bool
      shrinkWrapAndNeverScroll; // 外部嵌套Column或ListView时，为了保证还可嵌套ListView。但这会导致懒加载失效
  final void Function(int index)? onClick; // 点击动漫事件

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        //解决无限高度问题
        shrinkWrap: shrinkWrapAndNeverScroll ? true : false,
        //禁用滑动事件
        physics: shrinkWrapAndNeverScroll
            ? const NeverScrollableScrollPhysics()
            : null,
        itemCount: animes.length,
        itemBuilder: (context, index) {
          Log.info("$runtimeType: index=$index");
          Anime anime = animes[index];
          return AnimeListTile(
              isThreeLine: isThreeLine,
              anime: anime,
              index: index,
              animeTileSubTitle: animeTileSubTitle,
              showReviewNumber: showReviewNumber,
              showTrailingProgress: showTrailingProgress,
              onClick: onClick);
        });
  }
}

class AnimeListTile extends StatelessWidget {
  const AnimeListTile({
    Key? key,
    this.isThreeLine = false,
    required this.anime,
    required this.index,
    this.animeTileSubTitle,
    this.showReviewNumber = false,
    this.showTrailingProgress = false,
    this.onClick,
  }) : super(key: key);

  final bool isThreeLine;
  final Anime anime;
  final int index;
  final AnimeTileSubTitle? animeTileSubTitle;
  final bool showReviewNumber;
  final bool showTrailingProgress;
  final void Function(int index)? onClick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      isThreeLine: isThreeLine,
      title:
          Text(anime.animeName, maxLines: 2, overflow: TextOverflow.ellipsis),
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
              showReviewNumber: !SPUtil.getBool("hideReviewNumber"),
              reviewNumber: anime.reviewNumber,
            )
          : AnimeGridCover(anime, onlyShowCover: true),
      trailing: showTrailingProgress
          ? Text("${anime.checkedEpisodeCnt}/${anime.animeEpisodeCnt}",
              textScaleFactor: 0.9)
          : null,
      onTap: () {
        if (onClick != null) {
          onClick!(index);
        }
      },
    );
  }
}
