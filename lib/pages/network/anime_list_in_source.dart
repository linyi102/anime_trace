import 'package:flutter/material.dart';

import 'package:flutter_test_future/components/fade_animated_switcher.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/pages/network/climb/anime_climb_all_website.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../../models/anime.dart';

class AnimeListInSource extends StatefulWidget {
  final String sourceKeyword; // 表示搜索源的关键字
  const AnimeListInSource({Key? key, required this.sourceKeyword})
      : super(key: key);

  @override
  State<AnimeListInSource> createState() => _AnimeListInSourceState();
}

class _AnimeListInSourceState extends State<AnimeListInSource> {
  List<Anime> animes = [];
  bool loadOk = false;
  int cnt = 0;
  PageParams pageParams = PageParams(pageIndex: 0, pageSize: 50);

  @override
  void initState() {
    super.initState();
    // 获取动漫总数
    AnimeDao.getAnimesCntBySourceKeyword(widget.sourceKeyword).then((value) {
      cnt = value;
      Log.info("该搜索源下的动漫总数：$cnt");
      setState(() {});
    });
    // 获取动漫列表
    _loadData();
  }

  _loadData() {
    AnimeDao.getAnimesBySourceKeyword(
            sourceKeyword: widget.sourceKeyword, pageParams: pageParams)
        .then((value) {
      animes = value;
      loadOk = true;
      setState(() {});
    });
  }

  _loadMoreData() {
    pageParams.pageIndex++;
    Log.info("加载更多数据中，当前数量：${animes.length})");
    AnimeDao.getAnimesBySourceKeyword(
            sourceKeyword: widget.sourceKeyword, pageParams: pageParams)
        .then((value) {
      animes.addAll(value);
      Log.info("加载更多数据完毕，当前数量：${animes.length})");
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("收藏列表 ($cnt)",
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: FadeAnimatedSwitcher(
        destWidget: _buildAnimesListView(),
        loadOk: loadOk,
      ),
    );
  }

  _buildAnimesListView() {
    if (animes.isEmpty) return emptyDataHint("什么都没找到");
    return ListView.builder(
        itemCount: animes.length,
        itemBuilder: ((context, index) {
          if (index + 5 == pageParams.getQueriedSize()) {
            _loadMoreData();
          }
          Anime anime = animes[index];
          return ListTile(
              leading: AnimeListCover(anime),
              title: Text(anime.animeName),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                  return AnimeDetailPlus(anime);
                })).then((value) {
                  Anime retAnime = value as Anime;
                  String newUrl = retAnime.animeUrl;
                  Log.info("旧地址：${anime.animeUrl}，新地址：$newUrl");
                  if (anime.animeUrl != newUrl) {
                    Log.info("已迁移，从列表中删除");
                    animes.removeAt(index);
                    cnt = animes.length;
                  } else {
                    // 更新动漫(封面可能发生变化)
                    animes[index] = retAnime;
                  }
                });
              });
        }));
  }
}
