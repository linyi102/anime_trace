import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../components/anime_grid_cover.dart';
import '../../components/get_anime_grid_delegate.dart';
import '../../models/anime.dart';

class AnimeGridView extends StatefulWidget {
  const AnimeGridView(
      {required this.animes,
      required this.tagIdx,
      required this.scrollController,
      required this.loadMore,
      this.onClick,
      this.onLongClick,
      this.isSelected,
      Key? key})
      : super(key: key);

  final int tagIdx;
  final List<Anime> animes;
  final void Function(int animeIdx)? onClick;
  final void Function(int animeIdx)? onLongClick;
  final void Function(int tagIdx, int animeIdx) loadMore;
  final bool Function(int animeIdx)? isSelected;
  final ScrollController scrollController;

  @override
  State<AnimeGridView> createState() => _AnimeGridViewState();
}

class _AnimeGridViewState extends State<AnimeGridView>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GridView.builder(
        controller: widget.scrollController,
        // 整体的填充
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
        gridDelegate: getAnimeGridDelegate(context),
        itemCount: widget.animes.length,
        itemBuilder: (BuildContext context, int animeIdx) {
          widget.loadMore(widget.tagIdx, animeIdx);

          Anime anime = widget.animes[animeIdx];
          return ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: MaterialButton(
              onPressed: widget.onClick != null
                  ? () => widget.onClick!(animeIdx)
                  : null,
              onLongPress: widget.onLongClick != null
                  ? () => widget.onLongClick!(animeIdx)
                  : null,
              padding: const EdgeInsets.all(0),
              child: AnimeGridCover(anime,
                  isSelected: widget.isSelected == null
                      ? false
                      : widget.isSelected!(animeIdx)),
            ),
          );
        });
  }

  // 保证切换tab回来后仍然处于先前滚动位置
  // 1.有状态组件
  // 2.State class with AutomaticKeepAliveClientMixin
  // 3.覆写wantKeepAlive返回true
  @override
  bool get wantKeepAlive => true;
}
