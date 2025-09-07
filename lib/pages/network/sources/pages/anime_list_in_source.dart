import 'package:flutter/material.dart';
import 'package:animetrace/animation/fade_animated_switcher.dart';
import 'package:animetrace/components/anime_list_tile.dart';
import 'package:animetrace/components/empty_data_hint.dart';
import 'package:animetrace/dao/anime_dao.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/climb_website.dart';
import 'package:animetrace/models/params/page_params.dart';
import 'package:animetrace/pages/anime_detail/anime_detail.dart';
import 'package:animetrace/utils/log.dart';

class AnimeListInSource extends StatefulWidget {
  final ClimbWebsite website;
  const AnimeListInSource({Key? key, required this.website}) : super(key: key);

  @override
  State<AnimeListInSource> createState() => _AnimeListInSourceState();
}

class _AnimeListInSourceState extends State<AnimeListInSource> {
  List<Anime> animes = [];
  bool loadOk = false;
  int cnt = 0;
  PageParams pageParams = PageParams(pageIndex: 0, pageSize: 50);

  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 获取动漫总数
    AnimeDao.getAnimesCntInSource(widget.website.id).then((value) {
      cnt = value;
      AppLog.info("该搜索源下的动漫总数：$cnt");
      setState(() {});
    });
    // 获取动漫列表
    _loadData();
  }

  _loadData() {
    AnimeDao.getAnimesInSource(
            sourceId: widget.website.id, pageParams: pageParams)
        .then((value) {
      animes = value;
      loadOk = true;
      setState(() {});
    });
  }

  _loadMoreData() {
    pageParams.pageIndex++;
    AppLog.info("加载更多数据中，当前数量：${animes.length})");
    AnimeDao.getAnimesInSource(
            sourceId: widget.website.id, pageParams: pageParams)
        .then((value) {
      animes.addAll(value);
      AppLog.info("加载更多数据完毕，当前数量：${animes.length})");
      setState(() {});
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("收藏列表 ($cnt)"),
      ),
      body: Scrollbar(
        controller: scrollController,
        child: FadeAnimatedSwitcher(
          destWidget: _buildAnimesListView(),
          loadOk: loadOk,
        ),
      ),
    );
  }

  _buildAnimesListView() {
    if (animes.isEmpty) return emptyDataHint();
    return ListView.builder(
        controller: scrollController,
        itemCount: animes.length,
        itemBuilder: ((context, index) {
          if (index + 5 == pageParams.getQueriedSize()) {
            _loadMoreData();
          }
          Anime anime = animes[index];
          return AnimeListTile(
              anime: anime,
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return AnimeDetailPage(anime);
                })).then((value) {
                  Anime retAnime = value as Anime;
                  String newUrl = retAnime.animeUrl;
                  AppLog.info("旧地址：${anime.animeUrl}，新地址：$newUrl");
                  if (anime.animeUrl != newUrl || !retAnime.isCollected()) {
                    AppLog.info("已迁移或取消收藏，从列表中删除");
                    setState(() {
                      animes.removeAt(index);
                      cnt = animes.length;
                    });
                  } else {
                    // 更新动漫(封面可能发生变化)
                    setState(() {
                      animes[index] = retAnime;
                    });
                  }
                });
              });
        }));
  }
}
