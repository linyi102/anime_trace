import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
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

  @override
  void initState() {
    super.initState();
    AnimeDao.getAnimesBySourceKeyword(widget.sourceKeyword).then((value) {
      animes = value;
      loadOk = true;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("动漫迁移 (${animes.length})",
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: loadOk
          ? animes.isNotEmpty
              ? _buildAnimesListView()
              : emptyDataHint("什么都没找到")
          : const Center(
              child: RefreshProgressIndicator(),
            ),
    );
  }

  _buildAnimesListView() {
    return ListView.builder(
        itemCount: animes.length,
        itemBuilder: ((context, index) {
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
