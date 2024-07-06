import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/pages/network/sources/logic.dart';
import 'package:flutter_test_future/widgets/common_cover.dart';
import 'package:flutter_test_future/widgets/responsive.dart';
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
        mobile: _buildListView(100),
        desktop: _buildListView(140),
      ),
    );
  }

  Container _buildListView(double coverWidth) {
    final itemHeight = (coverWidth / 0.72) + 40;

    return Container(
      height: itemHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListView.builder(
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
