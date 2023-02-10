import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_grid_cover_auto_load.dart';
import 'package:flutter_test_future/components/get_anime_grid_delegate.dart';
import 'package:flutter_test_future/components/website_logo.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/models/week_record.dart';
import 'package:flutter_test_future/pages/anime_collection/search_db_anime.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/pages/network/weekly/weekly_controller.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/climb/climb_quqi.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/utils/time_show_util.dart';
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
  int selectedWeekday = DateTime.now().weekday; // 默认选中当天
  int get selectedWeekdayIdx => selectedWeekday - 1;

  final List<Climb> usableClimbs = [ClimbQuqi()];
  late ClimbWebsite curWebsite;

  late bool loading;

  bool enableSlide = false; // 开启左右滑动切换周几
  late final PageController pageController;

  @override
  void initState() {
    super.initState();

    pageController = PageController(initialPage: selectedWeekdayIdx);
    for (int i = 0; i < 7; ++i) {
      weeklyController.weeks.add([]);
    }

    // 默认为可用列表中的第一个，然后从所有搜索源中找到对应的下标
    int defaultIdx = climbWebsites.indexWhere((element) =>
        element.climb.runtimeType == usableClimbs.first.runtimeType);
    int websiteIdx =
        SPUtil.getInt(selectedWeeklyTableSourceIdx, defaultValue: defaultIdx);
    if (websiteIdx > climbWebsites.length) {
      websiteIdx = defaultIdx;
    } else {
      curWebsite = climbWebsites[websiteIdx];
    }

    // 为空时采才加载数据
    if (weeklyController.weeks[selectedWeekdayIdx].isEmpty) {
      loading = true;
      _loadData();
    } else {
      loading = false;
    }
  }

  _loadData() async {
    setState(() {
      loading = true;
    });

    weeklyController.weeks[selectedWeekdayIdx] =
        await ClimbAnimeUtil.climbWeekRecords(curWebsite, selectedWeekday);
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);

    return Column(
      children: [
        _buildSourceTile(),
        // 选择周几。放在最下面时，悬浮按钮会遮挡住，所以放到上面
        _buildWeeklyBar(),
        // 更新表
        _buildPageView(),
      ],
    );
  }

  Expanded _buildPageView() {
    return Expanded(
      child: PageView.builder(
        // 不允许滚动，因为tabbar也要滚动。所以改用底部周按钮来切换周几
        physics: enableSlide ? null : const NeverScrollableScrollPhysics(),
        controller: pageController,
        itemCount: weeklyController.weeks.length,
        onPageChanged: (changedPage) {
          selectedWeekday = changedPage + 1;
          Log.info(
              "changedPage=$changedPage, selectedWeekday=$selectedWeekday");
          if (weeklyController.weeks[selectedWeekdayIdx].isEmpty) {
            // 加载数据，里面会重新渲染，所以会同时渲染日期栏和动漫列表
            _loadData();
          } else {
            setState(() {
              // 需要重新渲染日期栏
            });
          }
        },
        itemBuilder: (context, pageIndex) {
          Log.info("pageIndex=$pageIndex");

          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => _loadData(),
            // child: _buildAnimeList(),
            child: GridView.builder(
              gridDelegate: getAnimeGridDelegate(context),
              // 不要使用selectedWeekdayIdx，而应使用pageIndex，否则生成的都是同一个页面
              itemCount: weeklyController.weeks[pageIndex].length,
              itemBuilder: (context, recordIdx) {
                // Log.info("recordIdx=$recordIdx");
                WeekRecord record =
                    weeklyController.weeks[pageIndex][recordIdx];

                return Column(
                  children: [
                    AnimeGridCoverAutoLoad(
                      anime: record.anime,
                      onChanged: (newAnime) => record.anime = newAnime,
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  ListView _buildAnimeList() {
    return ListView.builder(
      itemCount: weeklyController.weeks[selectedWeekdayIdx].length,
      itemBuilder: (context, recordIdx) {
        // Log.info("recordIdx=$recordIdx");
        WeekRecord record =
            weeklyController.weeks[selectedWeekdayIdx][recordIdx];

        return ListTile(
          title: Text(record.anime.animeName,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(record.info),
          onTap: () {
            Log.info(record.anime.animeUrl);
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SearchDbAnime(kw: record.anime.animeName),
                ));
          },
        );
      },
    );
  }

  _buildWeeklyBar() {
    return WeeklyBar(
      // 必须添加key，才能保证左右滑动pageview后，setState重新渲染WeeklyBar后，发生变化
      key: Key("weekley-bar-$selectedWeekday"),
      selectedWeekday: selectedWeekday,
      onChanged: (newWeekday) {
        Log.info("newWeekday=$newWeekday");
        selectedWeekday = newWeekday;
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
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            children: climbWebsites.map((e) {
              if (e.discard) return Container();

              // 如果该搜索源e的climb工具在usableClimbs中，则显示可用
              bool usable = usableClimbs.indexWhere(
                    (element) => element.runtimeType == e.climb.runtimeType,
                  ) >=
                  0;
              return ListTile(
                title: Text(
                  e.name,
                  style: usable ? null : const TextStyle(color: Colors.grey),
                ),
                leading: WebSiteLogo(url: e.iconUrl, size: 25),
                trailing:
                    e.name == curWebsite.name ? const Icon(Icons.check) : null,
                enabled: usable,
                onTap: () {
                  curWebsite = e;
                  SPUtil.setInt(selectedDirectorySourceIdx,
                      climbWebsites.indexWhere((element) => element == e));

                  _loadData();
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

/// 周日期栏
/// 不要转为无状态组件，因为要传入selectedWeekday，而它不是const，所以无法使用const WeeklyBar
/// 那么重新渲染时也会重新渲染WeeklyBar
class WeeklyBar extends StatefulWidget {
  const WeeklyBar({this.selectedWeekday = 1, this.onChanged, super.key});
  final int selectedWeekday;
  final void Function(int newWeekday)? onChanged;

  @override
  State<WeeklyBar> createState() => _WeeklyBarState();
}

class _WeeklyBarState extends State<WeeklyBar> {
  List<DateTime> weekDateTimes = [];
  late int selectedWeekday;
  final DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();

    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    Log.info("now: $now, monday: $monday");

    selectedWeekday = widget.selectedWeekday;
    for (int i = 0; i < 7; ++i) {
      weekDateTimes.add(monday.add(Duration(days: i)));
    }
  }

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);

    return Container(
      padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
      child: Row(
        children: weekDateTimes.map((dateTime) {
          // 周几
          int weekday = dateTime.weekday;
          // 是否被选中
          bool isSelected = dateTime.weekday == selectedWeekday;

          return Expanded(
            child: MaterialButton(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              onPressed: () {
                Log.info("点击weekday: $weekday");
                setState(() {
                  selectedWeekday = weekday;
                });
                if (widget.onChanged != null) {
                  widget.onChanged!(weekday);
                }
              },
              child: Column(
                children: [
                  // 显示周几
                  Text(TimeShowUtil.getChineseWeekdayByNumber(weekday),
                      style: const TextStyle(color: Colors.grey)),
                  // 显示日期
                  Container(
                    width: 24,
                    child: Center(
                        child: Text(
                      dateTime.day == now.day ? "今" : "${dateTime.day}",
                      style: TextStyle(color: isSelected ? Colors.white : null),
                    )),
                    decoration: isSelected
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            color: ThemeUtil.getPrimaryColor())
                        : const BoxDecoration(),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}