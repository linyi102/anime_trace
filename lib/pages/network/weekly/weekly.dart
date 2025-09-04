import 'package:flutter/material.dart';
import 'package:animetrace/components/anime_item_auto_load.dart';
import 'package:animetrace/components/get_anime_grid_delegate.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/components/website_logo.dart';
import 'package:animetrace/models/climb_website.dart';
import 'package:animetrace/models/week_record.dart';
import 'package:animetrace/pages/network/weekly/weekly_bar.dart';
import 'package:animetrace/pages/network/weekly/weekly_controller.dart';
import 'package:animetrace/utils/climb/climb_anime_util.dart';
import 'package:animetrace/utils/global_data.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/sp_util.dart';
import 'package:animetrace/values/values.dart';

/// 周表
class WeeklyPage extends StatefulWidget {
  const WeeklyPage({super.key});

  @override
  State<WeeklyPage> createState() => _WeeklyPageState();
}

class _WeeklyPageState extends State<WeeklyPage> {
  final weeklyController = WeeklyController();
  int get selectedWeekdayIdx => weeklyController.selectedWeekday - 1;

  final List<ClimbWebsite> usableWebsites = [
    bangumiClimbWebsite,
    quClimbWebsite,
  ];
  late ClimbWebsite curWebsite;
  bool get needClimbDetail =>
      [bangumiClimbWebsite, quClimbWebsite].contains(curWebsite);

  late bool loading;

  bool enableSlide = true; // 开启左右滑动切换周几
  late final PageController pageController;

  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    pageController = PageController(initialPage: selectedWeekdayIdx);

    // 默认为可用列表中的第一个，然后从所有搜索源中找到对应的下标
    int defaultIdx =
        climbWebsites.indexWhere((element) => element == usableWebsites.first);
    int websiteIdx =
        SPUtil.getInt(selectedWeeklyTableSourceIdx, defaultValue: defaultIdx);
    if (websiteIdx > climbWebsites.length) {
      websiteIdx = defaultIdx;
    } else {
      curWebsite = climbWebsites[websiteIdx];
    }

    _loadData();
  }

  _loadData() async {
    setState(() {
      loading = true;
    });

    weeklyController.weeks = await ClimbAnimeUtil.climbWeeklyTable(curWebsite);
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    weeklyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('周表')),
      body: Column(
        children: [
          Card(
            child: Column(
              children: [
                _buildSourceTile(),
                // 选择周几。放在最下面时，悬浮按钮会遮挡住，所以放到上面
                _buildWeeklyBar(),
              ],
            ),
          ),
          // 更新表
          _buildPageView(),
        ],
      ),
    );
  }

  Expanded _buildPageView() {
    return Expanded(
      child: PageView.builder(
        physics: enableSlide ? null : const NeverScrollableScrollPhysics(),
        controller: pageController,
        itemCount: weeklyController.weeks.length,
        onPageChanged: (changedPage) {
          setState(() {
            weeklyController.selectedWeekday = changedPage + 1;
          });
        },
        itemBuilder: (context, pageIndex) {
          AppLog.info("pageIndex=$pageIndex");

          if (loading) {
            return const LoadingWidget(center: true);
          }
          return Scrollbar(
            controller: scrollController,
            child: RefreshIndicator(
              onRefresh: () => _loadData(),
              child: _buildAnimeList(pageIndex),
              // child: _buildAnimeGrid(pageIndex),
            ),
          );
        },
      ),
    );
  }

  // ignore: unused_element
  GridView _buildAnimeGrid(int pageIndex) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 40),
      controller: scrollController,
      gridDelegate: getAnimeGridDelegate(context),
      // 不要使用selectedWeekdayIdx，而应使用pageIndex，否则生成的都是同一个页面
      itemCount: weeklyController.weeks[pageIndex].length,
      itemBuilder: (context, recordIdx) {
        // AppLog.info("recordIdx=$recordIdx");
        WeekRecord record = weeklyController.weeks[pageIndex][recordIdx];

        return Column(
          children: [
            AnimeItemAutoLoad(
              anime: record.anime,
              onChanged: (newAnime) => record.anime = newAnime,
              style: AnimeItemStyle.grid,
              showProgress: true,
              showReviewNumber: true,
              climbDetail: needClimbDetail,
            ),
          ],
        );
      },
    );
  }

  _buildAnimeList(int pageIndex) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 40),
      controller: scrollController,
      itemCount: weeklyController.weeks[pageIndex].length,
      itemBuilder: (context, recordIdx) {
        // AppLog.info("recordIdx=$recordIdx");
        WeekRecord record = weeklyController.weeks[pageIndex][recordIdx];
        return AnimeItemAutoLoad(
          anime: record.anime,
          onChanged: (newAnime) => record.anime = newAnime,
          style: AnimeItemStyle.list,
          subtitles: [record.info],
          showProgress: true,
          showReviewNumber: true,
          climbDetail: needClimbDetail,
        );
      },
    );
  }

  _buildWeeklyBar() {
    return WeeklyBar(
      controller: weeklyController,
      onChanged: (newWeekday) {
        AppLog.info("newWeekday=$newWeekday");
        // 切换页面较大时，短时间内播完动画有些卡顿，所以改用jump
        pageController.jumpToPage(selectedWeekdayIdx);
        // 跳转或动画到某页时，会指定pageView里的代码，所以把加载数据放在那里
      },
    );
  }

  // 构建当前搜索源
  _buildSourceTile() {
    return ListTile(
      title: Row(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WebSiteLogo(url: curWebsite.iconUrl, size: 25),
          const SizedBox(width: 10),
          Text(curWebsite.name),
        ],
      ),
      trailing: const Icon(Icons.keyboard_arrow_right),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            children: usableWebsites.map((e) {
              return ListTile(
                title: Text(e.name),
                leading: WebSiteLogo(url: e.iconUrl, size: 25),
                trailing:
                    e.name == curWebsite.name ? const Icon(Icons.check) : null,
                onTap: () {
                  // 记录
                  curWebsite = e;
                  SPUtil.setInt(selectedWeeklyTableSourceIdx,
                      climbWebsites.indexWhere((element) => element == e));
                  // 修改搜索源后，需要清空所有星期的动漫，避免保留了之前搜索源留下的动漫列表
                  weeklyController.clearWeeks();
                  // 加载数据
                  _loadData();
                  // 关闭选择框
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
