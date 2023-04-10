import 'package:flutter/material.dart';

import 'package:flutter_test_future/animation/fade_animated_switcher.dart';
import 'package:flutter_test_future/components/anime_item_auto_load.dart';
import 'package:flutter_test_future/components/anime_list_tile.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/play_status.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/utils/log.dart';

class NeedUpdateAnimeList extends StatefulWidget {
  const NeedUpdateAnimeList({Key? key}) : super(key: key);

  @override
  State<NeedUpdateAnimeList> createState() => _NeedUpdateAnimeListState();
}

class _NeedUpdateAnimeListState extends State<NeedUpdateAnimeList> {
  List<Anime> animes = [];
  bool loadOk = false;
  int cnt = 0;

  bool useCard = true;

  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
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
        title: Text("未完结 ($cnt)"),
      ),
      body: Scrollbar(
        controller: scrollController,
        child: FadeAnimatedSwitcher(
          destWidget:
              useCard ? _buildAnimeCardListView() : _buildAnimeTileListView(),
          loadOk: loadOk,
        ),
      ),
    );
  }

  ListView _buildAnimeCardListView() {
    return ListView.builder(
      controller: scrollController,
      itemCount: animes.length,
      itemBuilder: (context, index) => AnimeItemAutoLoad(
        anime: animes[index],
        showProgress: false,
        showReviewNumber: false,
        onChanged: (newAnime) {
          Log.info("onChanged");
          // animes[index] = newAnime;
          String newPlayStatus = newAnime.playStatus;
          Log.info("旧状态：${animes[index].playStatus}，新状态：$newPlayStatus");
          if (newPlayStatus.contains("完结")) {
            Log.info("已完结，从列表中删除");
            setState(() {
              animes.removeAt(index);
              cnt = animes.length;
            });
            // 下拉再往上翻才能看到消失了，不过并不影响
          } else {
            animes[index] = newAnime;
          }
        },
        showAnimeInfo: true,
      ),
    );
  }

  _buildAnimeTileListView() {
    return ListView.builder(
        controller: scrollController,
        itemCount: animes.length,
        itemBuilder: (context, index) {
          Log.info("$runtimeType: index=$index");
          Anime anime = animes[index];
          return AnimeListTile(
            isThreeLine: true,
            anime: anime,
            animeTileSubTitle: AnimeTileSubTitle.twoLinesOfInfo,
            showReviewNumber: false,
            showTrailingProgress: false,
            onTap: () {
              _enterAnimeDetailPage(anime, index);
            },
          );
        });
  }

  _enterAnimeDetailPage(Anime anime, int index) {
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
  }
}
