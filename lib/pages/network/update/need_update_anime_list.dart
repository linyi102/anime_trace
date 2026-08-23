import 'package:flutter/material.dart';

import 'package:animetrace/components/anime_item_auto_load.dart';
import 'package:animetrace/components/common_tab_bar.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/controllers/setting_service.dart';
import 'package:animetrace/dao/anime_dao.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/enum/play_status.dart';
import 'package:animetrace/utils/time_util.dart';
import 'package:animetrace/widgets/bottom_sheet.dart';
import 'package:animetrace/widgets/common_tab_bar_view.dart';

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
        title: Text("${_displayAnimes.length} 个$_displayAnimeStatusText"),
        actions: [
          IconButton(
            onPressed: _showDisplaySettingBottomSheet,
            icon: const Icon(Icons.layers_outlined),
          ),
        ],
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
      filteredAnimes = _displayAnimes;
    } else if (weekday == unknownWeeklyItem.weekday) {
      filteredAnimes = _displayAnimes
          .where((anime) => anime.premiereDateTime == null)
          .toList();
    } else if (1 <= weekday && weekday <= 7) {
      filteredAnimes = _displayAnimes
          .where((anime) => anime.premiereDateTime?.weekday == weekday)
          .toList();
    }
    return filteredAnimes;
  }

  List<Anime> get _displayAnimes {
    if (!SettingService.to.getNeedUpdateAnimeOnlyShowPlaying()) {
      return animes;
    }
    return animes
        .where((anime) => anime.getPlayStatus() == PlayStatus.playing)
        .toList();
  }

  String get _displayAnimeStatusText {
    return SettingService.to.getNeedUpdateAnimeOnlyShowPlaying()
        ? '连载中'
        : '未完结';
  }

  void _showDisplaySettingBottomSheet() {
    showCommonModalBottomSheet(
      context: context,
      builder: (context) => _NeedUpdateAnimeDisplaySettingSheet(
        onChanged: () => setState(() {}),
      ),
    );
  }
}

class _NeedUpdateAnimeDisplaySettingSheet extends StatefulWidget {
  const _NeedUpdateAnimeDisplaySettingSheet({required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<_NeedUpdateAnimeDisplaySettingSheet> createState() =>
      _NeedUpdateAnimeDisplaySettingSheetState();
}

class _NeedUpdateAnimeDisplaySettingSheetState
    extends State<_NeedUpdateAnimeDisplaySettingSheet> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('界面'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          SwitchListTile(
            title: const Text('只显示连载中动漫'),
            value: SettingService.to.getNeedUpdateAnimeOnlyShowPlaying(),
            onChanged: (value) {
              SettingService.to.setNeedUpdateAnimeOnlyShowPlaying(value);
              widget.onChanged();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

class WeeklyItem {
  String title;
  String subtitle;
  int weekday;
  WeeklyItem({required this.title, this.subtitle = '', required this.weekday});
}
