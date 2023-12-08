import 'package:flutter/material.dart';

import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/dialog/dialog_confirm_migrate.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_checklist.dart';
import 'package:flutter_test_future/controllers/anime_display_controller.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/widgets/responsive.dart';

/// 水平排列动漫封面
class AnimeHorizontalCover extends StatefulWidget {
  final List<Anime> animes;
  final int animeId;
  final Future<bool> Function() callback;

  const AnimeHorizontalCover(
      {Key? key,
      required this.animes,
      this.animeId = 0,
      required this.callback})
      : super(key: key);

  @override
  State<AnimeHorizontalCover> createState() => _AnimeHorizontalCoverState();
}

class _AnimeHorizontalCoverState extends State<AnimeHorizontalCover> {
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
      mobile: _buildListView(coverHeight: 150, coverWidth: 100),
      tablet: _buildListView(coverHeight: 175, coverWidth: 125),
      desktop: _buildListView(coverHeight: 200, coverWidth: 150),
    );
  }

  Container _buildListView(
      {required double coverHeight, required double coverWidth}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      height: coverHeight +
          (AnimeDisplayController.to.showNameInCover.value ? 10 : 60), // 设置高度
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.animes.length,
          itemBuilder: (context, animeIndex) {
            Anime anime = widget.animes[animeIndex];

            return Column(
              children: [
                AnimeGridCover(
                  anime,
                  coverWidth: coverWidth,
                  onPressed: () => _onTapAnime(anime, animeIndex),
                ),
                const Spacer(),
              ],
            );
          }),
    );
  }

  void _onTapAnime(Anime anime, int animeIndex) {
    if (ismigrate) {
      // 迁移动漫提示
      showDialogOfConfirmMigrate(context, widget.animeId, anime);
    } else if (anime.isCollected()) {
      Log.info("进入动漫详细页面${anime.animeId}");
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
          Log.info("callback.then");
          setState(() {});
        });
      });
    } else {
      Log.info("");
      dialogSelectChecklist(setState, context, anime);
    }
  }
}
