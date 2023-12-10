import 'package:flutter/material.dart';

import 'package:flutter_test_future/animation/fade_animated_switcher.dart';
import 'package:flutter_test_future/components/anime_item_auto_load.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/play_status.dart';
import 'package:flutter_test_future/utils/time_util.dart';
import 'package:flutter_test_future/widgets/common_scaffold_body.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

class NeedUpdateAnimeList extends StatefulWidget {
  const NeedUpdateAnimeList({Key? key}) : super(key: key);

  @override
  State<NeedUpdateAnimeList> createState() => _NeedUpdateAnimeListState();
}

class _NeedUpdateAnimeListState extends State<NeedUpdateAnimeList> {
  List<Anime> animes = [];
  List<Anime> filteredAnimes = [];
  bool loadOk = false;

  final allWeeklyItem = WeeklyItem(title: '全部', weekday: 0);
  final unknownWeeklyItem = WeeklyItem(title: '未知', weekday: -1);
  List<WeeklyItem> weeklyItems = [];
  late WeeklyItem curWeeklyItem;
  int get curBarItemIndex => weeklyItems.indexOf(curWeeklyItem);

  final scrollController = ScrollController();
  late final observerController =
      ListObserverController(controller: scrollController);

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

  _loadData() async {
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

    animes = await AnimeDao.getAllNeedUpdateAnimes(includeEmptyUrl: true);
    _sortAnimes();
    loadOk = true;
    _filterAnime();

    observerController.initialIndex = weeklyItems.indexOf(curWeeklyItem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${animes.length} 个未完结"),
      ),
      body: CommonScaffoldBody(
          child: FadeAnimatedSwitcher(
        destWidget: Column(
          children: [
            _buildWeeklyBar(),
            Expanded(child: _buildAnimeCardListView()),
          ],
        ),
        loadOk: loadOk,
      )),
    );
  }

  _buildWeeklyBar() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: ListViewObserver(
        controller: observerController,
        child: ListView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            children: [for (var item in weeklyItems) _buildWeeklyItem(item)]),
      ),
    );
  }

  _buildWeeklyItem(WeeklyItem item) {
    bool isCur = curWeeklyItem == item;
    var radius = BorderRadius.circular(12);

    return Container(
      decoration: BoxDecoration(
        color: isCur
            ? Theme.of(context).primaryColor
            : Theme.of(context).cardTheme.color,
        borderRadius: radius,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          setState(() {
            curWeeklyItem = item;
            _filterAnime();
          });

          observerController.animateTo(
            index: curBarItemIndex,
            duration: const Duration(milliseconds: 200),
            curve: Curves.linear,
            offset: (_) {
              return MediaQuery.of(context).size.width * 0.5;
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  color: isCur ? Colors.white : null,
                ),
              ),
              if (isCur && item.subtitle.isNotEmpty)
                Text(
                  item.subtitle,
                  style: TextStyle(
                      color: isCur ? Colors.white : Theme.of(context).hintColor,
                      fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  _buildAnimeCardListView() {
    return GridView.builder(
      key: ObjectKey(curWeeklyItem),
      itemCount: filteredAnimes.length,
      itemBuilder: (context, index) => _buildAnimeItem(index),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          mainAxisExtent: 140, maxCrossAxisExtent: 520),
    );
  }

  AnimeItemAutoLoad _buildAnimeItem(int index) {
    return AnimeItemAutoLoad(
      anime: filteredAnimes[index],
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
  void _filterAnime() {
    int weekday = curWeeklyItem.weekday;
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

    if (mounted) setState(() {});
  }
}

class WeeklyItem {
  String title;
  String subtitle;
  int weekday;
  WeeklyItem({required this.title, this.subtitle = '', required this.weekday});
}
