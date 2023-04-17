import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/get_anime_grid_delegate.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:get/get.dart';

class AnimeGridView extends StatefulWidget {
  const AnimeGridView(
      {required this.animes,
      required this.tagIdx,
      required this.scrollController,
      required this.loadMore,
      this.showProgressBar = false,
      this.onClick,
      this.onLongClick,
      this.isSelected,
      Key? key})
      : super(key: key);

  final int tagIdx;
  final List<Anime> animes;
  final bool showProgressBar;
  final void Function(Anime anime)? onClick;
  final void Function(Anime anime)? onLongClick;
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

    // 这里添加obx是为了当设置标题在封面下时，网格也能变化，否则会造成溢出
    return Obx(
      () => GridView.builder(
          controller: widget.scrollController,
          // 整体的填充
          padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
          gridDelegate: getAnimeGridDelegate(context),
          itemCount: widget.animes.length,
          itemBuilder: (BuildContext context, int animeIdx) {
            widget.loadMore(widget.tagIdx, animeIdx);

            Anime anime = widget.animes[animeIdx];
            return InkWell(
              onTap:
                  widget.onClick != null ? () => widget.onClick!(anime) : null,
              onLongPress: widget.onLongClick != null
                  ? () => widget.onLongClick!(anime)
                  : null,
              borderRadius: BorderRadius.circular(AppTheme.imgRadius),
              child: AnimeGridCover(anime,
                  showProgressBar: widget.showProgressBar,
                  isSelected: widget.isSelected == null
                      ? false
                      : widget.isSelected!(animeIdx)),
            );
          }),
    );
  }

  // 保证切换tab回来后仍然处于先前滚动位置
  // 1.有状态组件
  // 2.State class with AutomaticKeepAliveClientMixin
  // 3.覆写wantKeepAlive返回true
  @override
  bool get wantKeepAlive => true;
}
