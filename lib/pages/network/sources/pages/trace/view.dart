import 'package:animetrace/components/common_image.dart';
import 'package:animetrace/values/theme.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/dao/anime_dao.dart';
import 'package:animetrace/dao/history_dao.dart';
import 'package:animetrace/dao/note_dao.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/pages/anime_detail/anime_detail.dart';
import 'package:animetrace/utils/time_util.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

/// 总览
class TracePage extends StatefulWidget {
  const TracePage({super.key});

  @override
  State<TracePage> createState() => _TracePageState();
}

class _TracePageState extends State<TracePage> {
  Anime? firstCollectedAnime;
  Anime? firstWatchedAnime;
  String? firstWatchTime;
  Anime? firstPremieredAnime;
  Anime? maxReviewCntAnime;
  int? maxReviewCnt;

  int animeTotal = 0;
  int recordTotal = 0;
  int noteTotal = 0;
  int rateTotal = 0;

  bool loading = false;

  get bold => FontWeight.w600;

  @override
  void initState() {
    super.initState();
    _loadData(firstLoading: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('总览')),
      body: _buildBody(),
    );
  }

  _buildBody() {
    // if (loading) return loadingWidget(context);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        children: [
          _buildCountRow(),
          _buildCard(anime: firstCollectedAnime, title: '最早收藏'),
          _buildCard(
            anime: firstWatchedAnime,
            title: '最早观看',
            subtitle: TimeUtil.getChineseDate(firstWatchTime ?? ''),
          ),
          _buildCard(
            anime: firstPremieredAnime,
            title: '最早开播',
            subtitle: TimeUtil.getChineseDate(
                firstPremieredAnime?.premiereTime ?? ''),
          ),
          _buildCard(
            anime: maxReviewCntAnime,
            title: '回顾最多',
            subtitle: '$maxReviewCnt次',
          ),
        ],
      ),
    );
  }

  Card _buildCountRow() {
    Color? iconColor = Theme.of(context).colorScheme.primary;
    // iconColor = null;

    return Card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCountItem(
            title: '已收藏',
            subtitle: '$animeTotal',
            icon: Icon(MingCuteIcons.mgc_heart_line, color: iconColor),
            // icon: const Icon(Icons.favorite, color: Colors.red),
          ),
          _buildVerticalDivider(),
          _buildCountItem(
              title: '已观看',
              subtitle: '$recordTotal 集',
              icon: Icon(MingCuteIcons.mgc_history_line, color: iconColor)),
          _buildVerticalDivider(),
          _buildCountItem(
              title: '笔记数',
              subtitle: '$noteTotal',
              icon: Icon(MingCuteIcons.mgc_quill_pen_line, color: iconColor)),
          _buildVerticalDivider(),
          _buildCountItem(
              title: '评价数',
              subtitle: '$rateTotal',
              icon: Icon(MingCuteIcons.mgc_chat_4_line, color: iconColor)),
        ],
      ),
    );
  }

  Container _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.black12,
    );
  }

  Container _buildCountItem({
    required String title,
    required String subtitle,
    required Icon icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 16, height: 1.2),
          ),
        ],
      ),
    );
  }

  _buildCard({
    required Anime? anime,
    required String title,
    String subtitle = "",
  }) {
    if (anime == null) return const SizedBox.shrink();

    // var sigma = 20.0;

    return Container(
      height: 150,
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          onTap: () async {
            var value = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnimeDetailPage(anime),
                ));
            value as Anime;
            // 因为anime是形参，所以重绘后不是指向的value，所以要通过形参anime修改信息，而不是指向新的anime(也就是value)
            anime.animeName = value.animeName;
            anime.animeDesc = value.animeDesc;
            anime.animeCoverUrl = value.animeCoverUrl;
            setState(() {});
          },
          child: Row(
            children: [
              Expanded(
                child: Stack(children: [
                  // 模糊图片
                  // ConstrainedBox(
                  //   constraints: const BoxConstraints.expand(),
                  //   child: ImageFiltered(
                  //     imageFilter: ImageFilter.blur(
                  //       sigmaX: sigma,
                  //       sigmaY: sigma,
                  //     ),
                  //     child: CommonImage(anime.animeCoverUrl),
                  //   ),
                  // ),
                  // 文字
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(fontSize: 18, fontWeight: bold),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        // Padding(
                        //   padding: const EdgeInsets.symmetric(vertical: 8),
                        //   child: Container(
                        //     height: 0.5,
                        //     color: Theme.of(context).hintColor.withOpacity(0.2),
                        //   ),
                        // ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                anime.animeName,
                                style: const TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        // // const Spacer(),
                        Text(
                          anime.animeDesc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  )
                ]),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.imgRadius),
                child: SizedBox(
                  width: 100,
                  child: CommonImage(anime.animeCoverUrl),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadData({bool firstLoading = false}) async {
    if (firstLoading) {
      // await Future.delayed(const Duration(milliseconds: 400));
      loading = true;
      if (mounted) setState(() {});
    }
    // firstCollectedAnime = await SqliteUtil.getAnimeByAnimeId(353);
    // firstWatchTime = "2021-12-24";
    // firstWatchedAnime = await SqliteUtil.getAnimeByAnimeId(308);
    // firstPremieredAnime = await SqliteUtil.getAnimeByAnimeId(616);
    // maxReviewCntAnime = await SqliteUtil.getAnimeByAnimeId(158);
    firstCollectedAnime = await AnimeDao.getFirstCollectedAnime();

    var firstHistory = await HistoryDao.getFirstHistory();
    if (firstHistory != null) {
      firstWatchTime = firstHistory['date'];
      firstWatchedAnime = firstHistory['anime'];
    }
    firstPremieredAnime = await AnimeDao.getFirstPremieredAnime();

    // 可能会有多个最大回顾数，但只显示1个
    // 回顾数应从历史表中获取，因为动漫表里的回顾数可以修改成小的，不准确
    var map = await AnimeDao.getMaxReviewCntAnime();
    if (map != null) {
      maxReviewCnt = map['maxReviewCnt'];
      maxReviewCntAnime = map['anime'];
    }
    // 最大回顾数都为1时，不进行显示
    if (maxReviewCnt == 1) maxReviewCntAnime = null;

    animeTotal = await AnimeDao.getTotal();
    recordTotal = await HistoryDao.getCount();
    noteTotal = await NoteDao.getNotEmptyEpisodeNoteTotal();
    rateTotal = await NoteDao.getRateNoteTotal();

    loading = false;
    if (mounted) setState(() {});
  }
}
