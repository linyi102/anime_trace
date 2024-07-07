import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_item_auto_load.dart';
import 'package:flutter_test_future/components/get_anime_grid_delegate.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/components/website_logo.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/models/week_record.dart';
import 'package:flutter_test_future/pages/network/weekly/weekly_bar.dart';
import 'package:flutter_test_future/pages/network/weekly/weekly_controller.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:get/get.dart';

/// 周表
class WeeklyPage extends StatefulWidget {
  const WeeklyPage({super.key});

  @override
  State<WeeklyPage> createState() => _WeeklyPageState();
}

class _WeeklyPageState extends State<WeeklyPage> {
  final weeklyController = Get.put(WeeklyController());
  int get selectedWeekdayIdx => weeklyController.selectedWeekday - 1;

  final List<ClimbWebsite> usableWebsites = [
    bangumiClimbWebsite,
    quClimbWebsite,
  ];
  late ClimbWebsite curWebsite;
  bool get needClimbDetail => [quClimbWebsite].contains(curWebsite);

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);

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
          Log.info("pageIndex=$pageIndex");

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
        // Log.info("recordIdx=$recordIdx");
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
    // if (weeklyController.weeks[pageIndex].isEmpty) {
    //   return ListView( // ListView保证空数据下能够刷新
    //     children: [emptyDataHint()],
    //   );
    // }

    return ListView.builder(
      controller: scrollController,
      itemCount: weeklyController.weeks[pageIndex].length,
      itemBuilder: (context, recordIdx) {
        // Log.info("recordIdx=$recordIdx");
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
      selectedWeekday: weeklyController.selectedWeekday,
      onChanged: (newWeekday) {
        Log.info("newWeekday=$newWeekday");
        weeklyController.selectedWeekday = newWeekday;
        // 动画移动至指定页(页号从0开始，所以传入的是selectedWeekdayIdx而非selectedWeekday)
        // pageController
        //     .animateToPage(selectedWeekdayIdx,
        //         duration: const Duration(milliseconds: 2000),
        //         curve: Curves.linear).then((value) {
        //   // 动画播放完毕后，如果当前页没有数据，则进行加载
        //   if (weeklyController.weeks[selectedWeekdayIdx].isEmpty) {
        //     _loadData();
        //   }
        // });
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
