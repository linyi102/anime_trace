import 'package:flutter/material.dart';
import 'package:animetrace/components/anime_list_tile.dart';
import 'package:animetrace/values/values.dart';
import 'package:animetrace/widgets/setting_title.dart';

import '../../../../components/anime_grid_cover.dart';
import '../../../../components/get_anime_grid_delegate.dart';
import '../../../../controllers/anime_display_controller.dart';
import '../../../../dao/anime_dao.dart';
import '../../../../dao/anime_series_dao.dart';
import '../../../../models/anime.dart';
import '../../../../models/series.dart';
import '../../../../widgets/common_scaffold_body.dart';
import '../../../local_search/views/local_search_page.dart';
import '../../../anime_detail/anime_detail.dart';

class SeriesDetailPage extends StatefulWidget {
  final Series series;
  const SeriesDetailPage(this.series, {super.key});

  @override
  State<SeriesDetailPage> createState() => _SeriesDetailPageState();
}

class _SeriesDetailPageState extends State<SeriesDetailPage> {
  List<Anime> recommendAnimes = [];

  @override
  void initState() {
    super.initState();
    getAnimes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.series.name),
      ),
      body: CommonScaffoldBody(
          // child: _buildListView(),
          child: RefreshIndicator(
        onRefresh: () async => await getAnimes(),
        child: CustomScrollView(
          slivers: [
            _buildSeriesAnimesView(context),
            if (recommendAnimes.isNotEmpty)
              SliverToBoxAdapter(child: _buildRecommendTitle(context)),
            _buildRecommendedAnimes(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      )),
      floatingActionButton: _buildFAB(context),
    );
  }

  Future<void> _allAllRecommendAnimes() async {
    for (var anime in recommendAnimes) {
      await AnimeSeriesDao.insertAnimeSeries(anime.animeId, widget.series.id);
    }
    getAnimes();
  }

  SliverList _buildRecommendedAnimes() {
    return SliverList.builder(
      itemCount: recommendAnimes.length,
      itemBuilder: (context, index) {
        var color = Theme.of(context).colorScheme.primary;

        return AnimeListTile(
          anime: recommendAnimes[index],
          onTap: () => _toAnimeDetailPage(context, recommendAnimes, index),
          trailing: InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: () async {
              await AnimeSeriesDao.insertAnimeSeries(
                  recommendAnimes[index].animeId, widget.series.id);
              getAnimes();
            },
            child: Container(
              decoration: BoxDecoration(
                // color:color,
                border: Border.all(color: color),
                borderRadius: BorderRadius.circular(99),
              ),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: Text(
                '添加',
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      },
    );
  }

  SettingTitle _buildRecommendTitle(BuildContext context) {
    return SettingTitle(
      title: '推荐',
      trailing: _buildAddAllButton(),
    );
  }

  Widget? _buildAddAllButton() {
    if (recommendAnimes.isEmpty || recommendAnimes.length == 1) {
      return null;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: () {
        _allAllRecommendAnimes();
        // 最多只有几条数据，不需要加载圈，影响体验
        // ToastUtil.showLoading(
        //     msg: '添加中',
        //     task: () async {
        //       await _allAllRecommendAnimes();
        //     });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Text(
          '添加全部',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  _buildSeriesAnimesView(BuildContext context) {
    if (AnimeDisplayController.to.displayList.value) {
      return SliverList.builder(
        itemCount: widget.series.animes.length,
        itemBuilder: (context, index) {
          var anime = widget.series.animes[index];
          return AnimeListTile(
            anime: anime,
            onTap: () {
              _toAnimeDetailPage(context, widget.series.animes, index);
            },
            onLongPress: () {
              _showMoreOpDialog(context, anime);
            },
            showTrailingProgress: true,
          );
        },
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 5), // 整体的填充
      sliver: SliverGrid.builder(
        gridDelegate: getAnimeGridDelegate(context),
        itemCount: widget.series.animes.length,
        itemBuilder: (context, index) {
          var anime = widget.series.animes[index];
          return InkWell(
            borderRadius: BorderRadius.circular(AppTheme.imgRadius),
            onTap: () {
              _toAnimeDetailPage(context, widget.series.animes, index);
            },
            onLongPress: () {
              _showMoreOpDialog(context, anime);
            },
            child: AnimeGridCover(anime),
          );
        },
      ),
    );
  }

  Future<dynamic> _showMoreOpDialog(BuildContext context, Anime anime) {
    return showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('从系列中移除'),
            onTap: () {
              Navigator.pop(context);
              AnimeSeriesDao.deleteAnimeSeries(anime.animeId, widget.series.id);

              setState(() {
                widget.series.animes
                    .removeWhere((element) => element.animeId == anime.animeId);
              });
              // 重新获取推荐动漫
              getRecommendedAnimes();
            },
          )
        ],
      ),
    );
  }

  _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        var animeIds = widget.series.animes.map((e) => e.animeId).toList();
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DbAnimeSearchPage(
                kw: widget.series.name,
                hasSelectedAnimeIds: animeIds,
                onSelectOk: (selectedAnimeIds) async {
                  // 遍历新选择的ids
                  for (var animeId in selectedAnimeIds) {
                    // 当前系列中没有时，再进行添加，避免重复添加
                    if (!animeIds.contains(animeId)) {
                      await AnimeSeriesDao.insertAnimeSeries(
                          animeId, widget.series.id);
                    }
                  }

                  // 全部添加完毕后，重新获取该系列中的所有动漫
                  getAnimes();
                },
              ),
            ));
      },
      child: const Icon(Icons.add),
    );
  }

  void _toAnimeDetailPage(BuildContext context, List<Anime> animes, int index) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimeDetailPage(animes[index]),
        )).then((value) {
      getAnimes();
      // 不能简单替换动漫，因为可能会在里面进入系列修改数据了
      // setState(() {
      //   animes[index] = value;
      // });
    });
  }

  getAnimes() async {
    widget.series.animes =
        await AnimeSeriesDao.getAnimesBySeriesIds([widget.series.id]);
    getRecommendedAnimes();
    if (mounted) setState(() {});
  }

  getRecommendedAnimes() async {
    recommendAnimes = await AnimeDao.getAnimesBySearch(widget.series.name);
    // 移除系列中已添加的动漫
    for (var anime in widget.series.animes) {
      int index = recommendAnimes
          .indexWhere((element) => element.animeId == anime.animeId);
      if (index >= 0) {
        recommendAnimes.removeAt(index);
      }
    }
    if (mounted) setState(() {});
  }
}
