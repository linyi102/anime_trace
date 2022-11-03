import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/components/fade_animated_switcher.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/pages/network/climb/anime_climb_all_website.dart';

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
      debugPrint("该搜索源下的动漫总数：$cnt");
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
    debugPrint("加载更多数据中，当前数量：${animes.length})");
    AnimeDao.getAnimesBySourceKeyword(
            sourceKeyword: widget.sourceKeyword, pageParams: pageParams)
        .then((value) {
      animes.addAll(value);
      debugPrint("加载更多数据完毕，当前数量：${animes.length})");
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("动漫迁移 ($cnt)",
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
              Navigator.of(context).push(FadeRoute(builder: (context) {
                return AnimeClimbAllWebsite(
                  keyword: anime.animeName,
                  animeId: anime.animeId,
                );
              })).then((value) async {
                // 注意：无法根据动漫地址是否发生变化判断出有没有被迁移，因为并没有传入anime，里面的属性都不会变
                // 可以通过重新根据id获取动漫网址来判断是否变化
                String newUrl = await AnimeDao.getAnimeUrlById(anime.animeId);
                debugPrint("旧地址：${anime.animeUrl}，新地址：$newUrl");
                if (anime.animeUrl != newUrl) {
                  debugPrint("已迁移，从列表中删除");
                  animes.removeAt(index);
                }
              });
            },
          );
        }));
  }
}
