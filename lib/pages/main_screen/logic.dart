import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/main_screen/style.dart';
import 'package:flutter_test_future/pages/settings/series/manage/view.dart';
import 'package:get/get.dart';

import 'package:flutter_test_future/pages/anime_collection/anime_list_page.dart';
import 'package:flutter_test_future/pages/history/history_page.dart';
import 'package:flutter_test_future/pages/network/explore_page.dart';
import 'package:flutter_test_future/pages/note_list/note_list_page.dart';
import 'package:flutter_test_future/pages/settings/settings_page.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../network/climb/anime_climb_all_website.dart';

class MainScreenLogic extends GetxController {
  static MainScreenLogic get to => Get.find<MainScreenLogic>();

  int selectedTabIdx = 0;
  int get searchTabIdx => 1;

  List<MainTab> allTabs = [];
  List<MainTab> tabs = [];
  var homeTab = MainTab(
    name: "动漫",
    icon: const Icon(MingCuteIcons.mgc_home_4_line),
    selectedIcon: const Icon(MingCuteIcons.mgc_home_4_fill),
    page: const AnimeListPage(),
  );
  var exploreTab = MainTab(
    name: "探索",
    icon: const Icon(MingCuteIcons.mgc_search_line),
    selectedIcon: const Icon(MingCuteIcons.mgc_search_3_fill),
    page: const ExplorePage(),
  );
  var historyTab = MainTab(
    name: "历史",
    icon: const Icon(MingCuteIcons.mgc_time_line),
    selectedIcon: const Icon(MingCuteIcons.mgc_time_fill),
    page: const HistoryPage(),
  );
  var noteTab = MainTab(
    name: "笔记",
    icon: const Icon(MingCuteIcons.mgc_quill_pen_line),
    selectedIcon: const Icon(MingCuteIcons.mgc_quill_pen_fill),
    page: const NoteListPage(),
    show: MainScreenStyle.showNoteTabInMainScreen(),
    turnShow: () => MainScreenStyle.turnShowNoteTabInMainScreen(),
    canHide: true,
  );
  var seriesTab = MainTab(
    name: "系列",
    icon: const Icon(FluentIcons.collections_24_regular),
    selectedIcon: const Icon(FluentIcons.collections_24_filled),
    page: const SeriesManagePage(isHome: true),
    show: MainScreenStyle.showSeriesTabInMainScreen(),
    turnShow: () => MainScreenStyle.turnShowSeriesTabInMainScreen(),
    canHide: true,
  );
  var moreTab = MainTab(
    name: "更多",
    icon: const Icon(MingCuteIcons.mgc_more_3_line),
    selectedIcon: const Icon(MingCuteIcons.mgc_more_3_fill),
    page: const SettingPage(),
  );

  @override
  void onInit() {
    super.onInit();
    allTabs = [homeTab, exploreTab, historyTab, noteTab, seriesTab, moreTab];
    loadTabs(first: true);
  }

  loadTabs({bool first = false}) {
    tabs.clear();
    for (var tab in allTabs) {
      if (tab.show) {
        tabs.add(tab);
      }
    }
    // 调整后，始终保证当前打开的tab是最后一个
    if (!first) selectedTabIdx = tabs.length - 1;
    update();
  }

  toTabPage(int idx) {
    selectedTabIdx = idx;
    update();
  }

  toSearchTabPage() {
    selectedTabIdx = searchTabIdx;
    update();
  }

  openSearchPage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return const AnimeClimbAllWebsite();
      },
    ));
  }
}

class MainTab {
  String name;
  Widget icon;
  Widget? selectedIcon;
  Widget page;
  bool canHide;
  bool show;
  bool Function()? turnShow;

  MainTab({
    required this.name,
    required this.icon,
    this.selectedIcon,
    required this.page,
    this.canHide = false,
    this.show = true,
    this.turnShow,
  });
}
