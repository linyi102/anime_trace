import 'package:flutter/material.dart';

import 'package:flutter_test_future/components/anime_item_auto_load.dart';
import 'package:flutter_test_future/components/common_tab_bar.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/enum/play_status.dart';
import 'package:flutter_test_future/utils/time_util.dart';
import 'package:flutter_test_future/widgets/common_tab_bar_view.dart';

class NeedUpdateAnimeList extends StatefulWidget {
  const NeedUpdateAnimeList({Key? key}) : super(key: key);

  @override
  State<NeedUpdateAnimeList> createState() => _NeedUpdateAnimeListState();
}

class _NeedUpdateAnimeListState extends State<NeedUpdateAnimeList>
    with SingleTickerProviderStateMixin {
  List<Anime> animes = [];
  bool loadOk = false;

  final allWeeklyItem = WeeklyItem(title: '全部', weekday: 0);
  final unknownWeeklyItem = WeeklyItem(title: '未知', weekday: -1);
  List<WeeklyItem> weeklyItems = [];
  late WeeklyItem curWeeklyItem;

  late final tabController = TabController(length: 9, vsync: this);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    weeklyItems.addAll([allWeeklyItem, unknownWeeklyItem]);

    final now = DateTime.now();
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    for (int i = 0; i < 7; ++i) {
      var dateTime = monday.add(Duration(days: i));
      var item = WeeklyItem(
        title: '周${TimeUtil.getChineseWeekdayByNumber(dateTime.weekday)}',
        subtitle: '${dateTime.month}-${dateTime.day}',
        weekday: dateTime.weekday,
      );
      weeklyItems.add(item);
      if (now.weekday == dateTime.weekday) curWeeklyItem = item;
    }
    tabController.animateTo(weeklyItems.indexOf(curWeeklyItem));
    animes = await AnimeDao.getAllNeedUpdateAnimes(includeEmptyUrl: true);
    _sortAnimes();
    setState(() {
      loadOk = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${animes.length} 个未完结"),
        bottom: CommonBottomTabBar(
          isScrollable: true,
          tabController: tabController,
          tabs: [
            for (final item in weeklyItems)
              Tab(
                  child: Text.rich(TextSpan(children: [
                TextSpan(text: item.title),
                const WidgetSpan(child: SizedBox(width: 4)),
                TextSpan(
                  text: _filterAnime(item).length.toString(),
                  style: TextStyle(
                      fontSize:
                          Theme.of(context).textTheme.bodySmall?.fontSize),
                )
              ]))),
          ],
        ),
      ),
      body: CommonTabBarView(
        controller: tabController,
        children: [
          for (final item in weeklyItems)
            loadOk
                ? _buildAnimeCardListView(_filterAnime(item))
                : const LoadingWidget(),
        ],
      ),
    );
  }

  Widget _buildAnimeCardListView(List<Anime> animes) {
    if (animes.isEmpty) {
      return const Center(child: Text('什么都没有~'));
    }
    return GridView.builder(
      itemCount: animes.length,
      itemBuilder: (context, index) => _buildAnimeItem(animes[index]),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          mainAxisExtent: 140, maxCrossAxisExtent: 520),
    );
  }

  AnimeItemAutoLoad _buildAnimeItem(Anime anime) {
    return AnimeItemAutoLoad(
      anime: anime,
      showProgress: false,
      showReviewNumber: false,
      showWeekday: true,
      showAnimeInfo: true,
      onChanged: (Anime newAnime) {},
    );
  }

  /// 排序规则
  /// 1.连载中靠前，未开播靠后
  /// 2.首播时间
  void _sortAnimes() {
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
  }

  /// 筛选动漫
  List<Anime> _filterAnime(WeeklyItem weeklyItem) {
    final weekday = weeklyItem.weekday;
    List<Anime> filteredAnimes = [];

    if (weekday == allWeeklyItem.weekday) {
      filteredAnimes = animes;
    } else if (weekday == unknownWeeklyItem.weekday) {
      filteredAnimes =
          animes.where((anime) => anime.premiereDateTime == null).toList();
    } else if (1 <= weekday && weekday <= 7) {
      filteredAnimes = animes
          .where((anime) => anime.premiereDateTime?.weekday == weekday)
          .toList();
    }
    return filteredAnimes;
  }
}

class WeeklyItem {
  String title;
  String subtitle;
  int weekday;
  WeeklyItem({required this.title, this.subtitle = '', required this.weekday});
}
