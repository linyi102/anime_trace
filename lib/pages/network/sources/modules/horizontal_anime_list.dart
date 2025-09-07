import 'package:flutter/material.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/pages/anime_detail/anime_detail.dart';
import 'package:animetrace/pages/network/sources/aggregate_logic.dart';
import 'package:animetrace/widgets/common_cover.dart';
import 'package:animetrace/widgets/responsive.dart';
import 'package:get/get.dart';

class HorizontalAnimeListPage extends StatelessWidget {
  const HorizontalAnimeListPage({
    super.key,
    required this.animes,
    this.specifyItemSubtitle,
  });
  final List<Anime> animes;
  final String? Function(Anime anime)? specifyItemSubtitle;

  AggregateLogic get logic => AggregateLogic.to;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: logic,
      builder: (_) => Responsive(
        mobile: _buildListView(110),
        desktop: _buildListView(140),
      ),
    );
  }

  Widget _buildListView(double coverWidth) {
    final itemHeight = (coverWidth / 0.72) + 40;

    return SizedBox(
      height: itemHeight,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        itemCount: animes.length,
        itemBuilder: (context, index) {
          final anime = animes[index];
          return CommonCover(
            width: coverWidth,
            coverUrl: anime.animeCoverUrl,
            title: anime.animeName,
            subtitle: specifyItemSubtitle?.call(anime),
            onTap: () async {
              Anime value = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnimeDetailPage(anime),
                  ));
              anime.animeName = value.animeName;
              anime.animeCoverUrl = value.animeCoverUrl;
              logic.update();
            },
          );
        },
      ),
    );
  }
}
