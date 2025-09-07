import 'package:animetrace/components/anime_custom_cover.dart';
import 'package:animetrace/controllers/anime_display_controller.dart';
import 'package:animetrace/utils/platform.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/models/anime.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class AnimeGridView extends StatefulWidget {
  const AnimeGridView({
    Key? key,
    required this.animes,
    this.loadMore,
    this.scrollController,
    this.onTap,
    this.onLongPress,
    this.isSelected,
    this.sliver = false,
    this.styleBuilder,
  })  : assert(
          sliver == false || scrollController == null,
          'When sliver is true, scrollController must be null',
        ),
        super(key: key);

  final List<Anime> animes;
  final void Function(Anime anime)? onTap;
  final void Function(Anime anime)? onLongPress;
  final void Function(int animeIdx)? loadMore;
  final bool Function(int animeIdx)? isSelected;
  final ScrollController? scrollController;
  final bool sliver;
  final AnimeCoverStyle Function(AnimeCoverStyle style)? styleBuilder;

  @override
  State<AnimeGridView> createState() => _AnimeGridViewState();
}

class _AnimeGridViewState extends State<AnimeGridView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  AnimeDisplayController get _displayController => AnimeDisplayController.to;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      final enableResponsive =
          _displayController.enableResponsiveGridColumnCnt.value;
      final gridColumnCnt = _displayController.gridColumnCnt.value;
      final style = _displayController.coverStyle.value;
      const padding = EdgeInsets.fromLTRB(8, 4, 8, 30);

      Widget buildItem(int index) {
        // AppLog.debug('build anime $index');
        final anime = widget.animes[index];

        return CustomAnimeCover(
          anime: anime,
          style: widget.styleBuilder?.call(style) ?? style,
          onTap: widget.onTap != null ? () => widget.onTap!(anime) : null,
          onLongPress: widget.onLongPress != null
              ? () => widget.onLongPress!(anime)
              : null,
          selected:
              widget.isSelected == null ? false : widget.isSelected!(index),
        );
      }

      int calCrossAxisCount(double maxWidth) {
        if (enableResponsive) {
          return maxWidth ~/ (PlatformUtil.isDesktop ? 160 : 100);
        }
        return gridColumnCnt;
      }

      if (widget.sliver) {
        return SliverPadding(
          padding: padding,
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              return SliverAlignedGrid.count(
                crossAxisCount: calCrossAxisCount(constraints.crossAxisExtent),
                itemCount: widget.animes.length,
                itemBuilder: (context, index) {
                  widget.loadMore?.call(index);

                  return buildItem(index);
                },
              );
            },
          ),
        );
      }

      // Note: AlignedGridView可以在固定列数时不用指定比例
      return LayoutBuilder(
        builder: (context, constraints) {
          return AlignedGridView.count(
            controller: widget.scrollController,
            padding: padding,
            crossAxisCount: calCrossAxisCount(constraints.maxWidth),
            itemCount: widget.animes.length,
            itemBuilder: (context, index) {
              widget.loadMore?.call(index);

              return buildItem(index);
            },
          );
        },
      );
    });
  }
}
