import 'package:flutter/material.dart';
import 'package:animetrace/components/anime_custom_cover.dart';
import 'package:animetrace/components/dialog/dialog_confirm_migrate.dart';
import 'package:animetrace/components/dialog/dialog_select_checklist.dart';
import 'package:animetrace/controllers/anime_display_controller.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/pages/anime_detail/anime_detail.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/widgets/responsive.dart';

class AnimeHorizontalListView extends StatefulWidget {
  final List<Anime> animes;
  final int animeId;
  final Future<bool> Function() callback;
  final void Function(Anime anime)? onLongPressItem;
  final AnimeCoverStyle Function(AnimeCoverStyle style)? styleBuilder;

  const AnimeHorizontalListView({
    Key? key,
    required this.animes,
    this.animeId = 0,
    required this.callback,
    this.onLongPressItem,
    this.styleBuilder,
  }) : super(key: key);

  @override
  State<AnimeHorizontalListView> createState() =>
      _AnimeHorizontalListViewState();
}

class _AnimeHorizontalListViewState extends State<AnimeHorizontalListView> {
  bool ismigrate = false;

  @override
  void initState() {
    super.initState();
    ismigrate = widget.animeId > 0 ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: const Row(
          children: [Text("没有找到。")],
        ),
      );
    }

    return Responsive(
      mobile: _buildListView(coverWidth: 110),
      tablet: _buildListView(coverWidth: 130),
      desktop: _buildListView(coverWidth: 150),
    );
  }

  Container _buildListView({required double coverWidth}) {
    final style = AnimeDisplayController.to.coverStyle.value;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: SizedBox(
        height: coverWidth * 2.1,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.animes.length,
          itemBuilder: (context, index) {
            final anime = widget.animes[index];
            AppLog.debug('$coverWidth listview horizontal build $index');
            return Column(
              // 使用Column保证封面靠上
              children: [
                CustomAnimeCover(
                  width: coverWidth,
                  anime: anime,
                  style: widget.styleBuilder?.call(style) ?? style,
                  onTap: () => _onTapAnime(anime, index),
                  onLongPress: () => widget.onLongPressItem?.call(anime),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onTapAnime(Anime anime, int animeIndex) {
    if (ismigrate) {
      // 迁移动漫提示
      showDialogOfConfirmMigrate(context, widget.animeId, anime);
    } else if (anime.isCollected()) {
      AppLog.info("进入动漫详细页面${anime.animeId}");
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return AnimeDetailPage(anime);
          },
        ),
      ).then((value) async {
        // 使用widget.animes[animeIndex]而不是anime，才可以看到变化，比如完成集数
        // widget.animes[animeIndex] =
        //     await SqliteUtil.getAnimeByAnimeId(anime.animeId);
        // setState(() {});
        widget.animes[animeIndex] = value;
        widget.callback().then((value) {
          AppLog.info("callback.then");
          setState(() {});
        });
      });
    } else {
      dialogSelectChecklist(setState, context, anime);
    }
  }
}
