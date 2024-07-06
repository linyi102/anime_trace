import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/pages/network/sources/logic.dart';
import 'package:flutter_test_future/widgets/common_cover.dart';
import 'package:flutter_test_future/widgets/responsive.dart';
import 'package:get/get.dart';

class TodayAnimeListPage extends StatelessWidget {
  const TodayAnimeListPage({super.key});
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
        itemCount: logic.animesNYearsAgoTodayBroadcast.length,
        itemBuilder: (context, index) {
          final anime = logic.animesNYearsAgoTodayBroadcast[index];
          return CommonCover(
            width: coverWidth,
            coverUrl: anime.animeCoverUrl,
            title: anime.animeName,
            subtitle: _getDiffYear(anime),
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

  String _getDiffYear(Anime anime) {
    var year = DateTime.parse(anime.premiereTime).year;
    var diff = DateTime.now().year - year;
    String text = '';
    if (diff == 0) text = '今天';
    text = diff == 0 ? '今天' : '$diff 年前';
    return text;
  }
}
