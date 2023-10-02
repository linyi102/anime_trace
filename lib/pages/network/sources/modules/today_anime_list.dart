import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../components/anime_list_cover.dart';
import '../../../../models/anime.dart';
import '../../../anime_detail/anime_detail.dart';
import '../logic.dart';

class TodayAnimeListPage extends StatelessWidget {
  const TodayAnimeListPage({super.key});
  AggregateLogic get logic => AggregateLogic.to;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: logic,
        builder: (_) => Column(
              children: [
                for (var anime in logic.animesNYearsAgoTodayBroadcast)
                  ListTile(
                    title:
                        Text(anime.animeName, overflow: TextOverflow.ellipsis),
                    subtitle: Text(_getDiffYear(anime)),
                    leading: AnimeListCover(anime, showReviewNumber: false),
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
                  ),
                const SizedBox(height: 10),
              ],
            ));
  }

  String _getDiffYear(Anime anime) {
    var year = DateTime.parse(anime.premiereTime).year;
    var diff = DateTime.now().year - year;
    String text = '';
    if (diff == 0) text = '今天';
    text = diff == 0 ? '今天' : '$diff 年前的今天';
    return text;
  }
}
