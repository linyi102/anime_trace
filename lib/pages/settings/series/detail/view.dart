import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../../../components/anime_grid_cover.dart';
import '../../../../components/get_anime_grid_delegate.dart';
import '../../../../dao/anime_series_dao.dart';
import '../../../../models/anime.dart';
import '../../../../models/series.dart';
import '../../../../widgets/common_scaffold_body.dart';
import '../../../anime_collection/db_anime_search.dart';
import '../../../anime_detail/anime_detail.dart';

class SeriesDetailPage extends StatefulWidget {
  final Series series;
  const SeriesDetailPage(this.series, {super.key});

  @override
  State<SeriesDetailPage> createState() => _SeriesDetailPageState();
}

class _SeriesDetailPageState extends State<SeriesDetailPage> {
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
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(5, 0, 5, 5), // 整体的填充
          gridDelegate: getAnimeGridDelegate(context),
          itemCount: widget.series.animes.length,
          itemBuilder: (context, index) {
            var anime = widget.series.animes[index];
            return InkWell(
              onTap: () {
                _toAnimeDetailPage(context, anime, index);
              },
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (context) => SimpleDialog(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.delete),
                        title: const Text('从系列中移除'),
                        onTap: () {
                          Navigator.pop(context);
                          AnimeSeriesDao.deleteAnimeSeries(
                              anime.animeId, widget.series.id);

                          setState(() {
                            widget.series.animes.removeWhere(
                                (element) => element.animeId == anime.animeId);
                          });
                        },
                      )
                    ],
                  ),
                );
              },
              child: AnimeGridCover(anime),
            );
          },
        ),
      )),
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(MingCuteIcons.mgc_add_line),
      ),
    );
  }

  void _toAnimeDetailPage(BuildContext context, Anime anime, int index) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimeDetailPage(anime),
        )).then((value) {
      setState(() {
        widget.series.animes[index] = value;
      });
    });
  }

  getAnimes() async {
    widget.series.animes =
        await AnimeSeriesDao.getAnimesBySeriesIds([widget.series.id]);
    setState(() {});
  }
}
