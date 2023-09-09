import 'package:flutter/material.dart';
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

  List<MainTab> tabs = [];
  List<MainTab> candidateTabs = [];

  var homeTab = MainTab(
      name: "动漫",
      iconData: MingCuteIcons.mgc_home_4_line,
      selectedIconData: MingCuteIcons.mgc_home_4_fill,
      page: const AnimeListPage());
  var exploreTab = MainTab(
      name: "探索",
      iconData: MingCuteIcons.mgc_search_line,
      selectedIconData: MingCuteIcons.mgc_search_3_fill,
      page: const ExplorePage());
  var historyTab = MainTab(
      name: "历史",
      iconData: MingCuteIcons.mgc_time_line,
      selectedIconData: MingCuteIcons.mgc_time_fill,
      page: const HistoryPage());
  var noteTab = MainTab(
      name: "笔记",
      iconData: MingCuteIcons.mgc_quill_pen_line,
      selectedIconData: MingCuteIcons.mgc_quill_pen_fill,
      page: const NoteListPage());
  var moreTab = MainTab(
      name: "更多",
      iconData: MingCuteIcons.mgc_more_3_line,
      selectedIconData: MingCuteIcons.mgc_more_3_fill,
      page: const SettingPage());

  @override
  void onInit() {
    super.onInit();
    tabs = [
      homeTab,
      exploreTab,
      historyTab,
      noteTab,
      moreTab,
    ];
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
  IconData iconData;
  IconData? selectedIconData;
  Widget page;

  MainTab(
      {required this.name,
      required this.iconData,
      this.selectedIconData,
      required this.page});
}
