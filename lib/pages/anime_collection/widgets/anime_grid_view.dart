import 'package:animetrace/components/anime_cover.dart';
import 'package:animetrace/controllers/anime_display_controller.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/models/anime.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      final AnimeDisplayController _animeDisplayController = Get.find();
      final enableResponsive =
          _animeDisplayController.enableResponsiveGridColumnCnt.value;
      final gridColumnCnt = _animeDisplayController.gridColumnCnt.value;

      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = enableResponsive
              ? (constraints.maxWidth / 160).toInt()
              : gridColumnCnt;

          return AlignedGridView.count(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 30),
            crossAxisCount: crossAxisCount,
            itemCount: widget.animes.length,
            itemBuilder: (context, index) {
              widget.loadMore(widget.tagIdx, index);

              final anime = widget.animes[index];

              return CustomAnimeCover(
                anime: anime,
                style: const AnimeCoverStyle(
                  maxNameLines: 2,
                  progressLinearPlacement: Placement.none,
                ),
                onTap: widget.onClick != null
                    ? () => widget.onClick!(anime)
                    : null,
                onLongPress: widget.onLongClick != null
                    ? () => widget.onLongClick!(anime)
                    : null,
                selected: widget.isSelected == null
                    ? false
                    : widget.isSelected!(index),
              );
            },
          );
        },
      );
    });
  }
}
