import 'package:flutter/material.dart';

import 'package:flutter_test_future/components/fade_animated_switcher.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/play_status.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../../../models/anime.dart';
import '../../../components/anime_list_view.dart';

class NeedUpdateAnimeList extends StatefulWidget {
  const NeedUpdateAnimeList({Key? key}) : super(key: key);

  @override
  State<NeedUpdateAnimeList> createState() => _NeedUpdateAnimeListState();
}

class _NeedUpdateAnimeListState extends State<NeedUpdateAnimeList> {
  List<Anime> animes = [];
  bool loadOk = false;
  int cnt = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() {
    AnimeDao.getAllNeedUpdateAnimes().then((value) {
      // 排序规则
      // 1.连载中靠前，未开播靠后
      // 2.首播时间
      animes = value;
      animes.sort((a, b) {
        if (a.getPlayStatus() != b.getPlayStatus()) {
          if (a.getPlayStatus() == PlayStatus.playing) {
            return -1;
          } else {
            return 1;
          }
        } else {
          // 播放状态相同，比较首播时间
          return a.premiereTime.compareTo(b.premiereTime);
        }
      });
      // List<Anime> playingAnimes = [], notStartedAnimes = [];
      // for (var anime in value) {
      //   if (anime.getPlayStatus() == PlayStatus.playing) {
      //     playingAnimes.add(anime);
      //   } else {
      //     notStartedAnimes.add(anime);
      //   }
      // }
      // animes.addAll(playingAnimes);
      // animes.addAll(notStartedAnimes);

      cnt = animes.length;
      loadOk = true;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("未完结动漫 ($cnt)",
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: FadeAnimatedSwitcher(
        destWidget: AnimeListView(
          animes: animes,
          animeTileSubTitle: AnimeTileSubTitle.twoLinesOfInfo,
          isThreeLine: true,
          onClick: (index) {
            Anime anime = animes[index];

            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return AnimeDetailPage(anime);
            })).then((value) {
              Anime retAnime = value as Anime;
              String newPlayStatus = retAnime.playStatus;
              Log.info("旧状态：${anime.playStatus}，新状态：$newPlayStatus");
              if (newPlayStatus.contains("完结")) {
                Log.info("已完结，从列表中删除");
                animes.removeAt(index);
                cnt = animes.length;
                setState(() {});
              } else {
                // 更新动漫(封面可能发生变化)
                animes[index] = retAnime;
              }
            });
          },
        ),
        loadOk: loadOk,
      ),
    );
  }
}
