import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/backup_service.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/pages/anime_collection/anime_list_page.dart';
import 'package:flutter_test_future/pages/history/history_page.dart';
import 'package:flutter_test_future/pages/network/network_page.dart';
import 'package:flutter_test_future/pages/note_list/note_list_page.dart';
import 'package:flutter_test_future/pages/settings/settings_page.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/values/theme.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../widgets/common_divider.dart';
import '../network/climb/anime_climb_all_website.dart';

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

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTabIdx = 0;
  int _clickBackCnt = 0;
  int get searchIdx => 1;
  bool get enableAnimation => false;
  bool get alwaysPortrait => false;

  final List<MainTab> _mainTabs = [
    MainTab(
        name: "动漫",
        iconData: MingCuteIcons.mgc_home_4_line,
        selectedIconData: MingCuteIcons.mgc_home_4_fill,
        page: const AnimeListPage()),
    MainTab(
        name: "探索",
        iconData: MingCuteIcons.mgc_search_line,
        selectedIconData: MingCuteIcons.mgc_search_3_fill,
        page: const NetWorkPage()),
    MainTab(
        name: "历史",
        iconData: MingCuteIcons.mgc_time_line,
        selectedIconData: MingCuteIcons.mgc_time_fill,
        page: const HistoryPage()),
    MainTab(
        name: "笔记",
        iconData: MingCuteIcons.mgc_quill_pen_line,
        selectedIconData: MingCuteIcons.mgc_quill_pen_fill,
        page: const NoteListPage()),
    MainTab(
        name: "更多",
        iconData: MingCuteIcons.mgc_more_3_line,
        selectedIconData: MingCuteIcons.mgc_more_3_fill,
        page: const SettingPage())
  ];

  bool expandSideBar = SpProfile.getExpandSideBar();
  double get dividerThickness => 0.5;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: clickTwiceToExitApp,
      child: alwaysPortrait
          ? _buildPortraitScreen()
          : Platform.isAndroid &&
                  MediaQuery.of(context).orientation == Orientation.portrait
              ? _buildPortraitScreen()
              : _buildLandscapeScreen(),
    );
  }

  _buildLandscapeScreen() {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // 侧边栏
            _buildSideBar(),
            CommonDivider(
              thinkness: dividerThickness,
              direction: Axis.vertical,
            ),
            // 主体
            Expanded(child: _buildMainPage())
          ],
        ),
      ),
    );
  }

  Future<bool> clickTwiceToExitApp() async {
    _clickBackCnt++;
    if (_clickBackCnt == 2) {
      // 备份后退出
      BackupService.to.tryBackupBeforeExitApp(exitApp: () async {
        Global.exitApp();
      });
      // 始终返回false，暂时不退出App，等待备份成功后执行exitApp来退出
      return false;
    }
    Future.delayed(const Duration(seconds: 2)).then((value) {
      _clickBackCnt = 0;
      Log.info("点击返回次数重置为0");
    });
    ToastUtil.showText("再次点击退出应用");
    return false;
  }

  _buildSideBar() {
    return Material(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: AnimatedContainer(
        curve: Curves.fastOutSlowIn,
        width: expandSideBar ? 150 : 70,
        duration: const Duration(milliseconds: 200),
        child: CustomScrollView(
          slivers: [
            // SliverFillRemaining作用：在Column中使用Spacer
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: _buildSideMenu(),
              ),
            )
          ],
        ),
      ),
    );
  }

  _buildSideMenu() {
    List<Widget> widgets = [];

    widgets.add(Container(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset("assets/images/logo.png", height: 40, width: 40),
        ],
      ),
    ));

    for (int i = 0; i < _mainTabs.length; ++i) {
      var mainTab = _mainTabs[i];

      bool isSelected = _selectedTabIdx == i;
      widgets.add(
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
          margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            onTap: () {
              if (searchIdx == i && _selectedTabIdx == i) {
                // 如果点击的是探索页，且当前已在探索页，则进入聚合搜索页
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) {
                    return const AnimeClimbAllWebsite();
                  },
                ));
              } else {
                setState(() {
                  _selectedTabIdx = i;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
              child: Row(
                  mainAxisAlignment: expandSideBar
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Icon(isSelected
                        ? mainTab.selectedIconData ?? mainTab.iconData
                        : mainTab.iconData),
                    // 使用Spacer而不是固定宽度，这样展开时文字就不会溢出的
                    if (expandSideBar) const Spacer(flex: 2),
                    if (expandSideBar)
                      Expanded(
                        flex: 4,
                        child: Text(
                          mainTab.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : null),
                        ),
                      ),
                  ]),
            ),
          ),
        ),
      );
    }

    widgets.add(const Spacer());
    widgets.add(Divider(thickness: dividerThickness));
    widgets.add(Row(
      mainAxisAlignment:
          expandSideBar ? MainAxisAlignment.end : MainAxisAlignment.center,
      children: [
        IconButton(
          splashRadius: 24,
          icon: Icon(
            expandSideBar
                ? MingCuteIcons.mgc_left_line
                : MingCuteIcons.mgc_right_line,
            // 不适合暗色主题
            // color: Colors.black54,
          ),
          onPressed: () {
            SpProfile.turnExpandSideBar();
            setState(() {
              expandSideBar = !expandSideBar;
            });
          },
        ),
      ],
    ));

    return widgets;
  }

  _buildPortraitScreen() {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _buildMainPage(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CommonDivider(),
          NavigationBar(
              height: 60,
              elevation: 0,
              selectedIndex: _selectedTabIdx,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              indicatorColor: Colors.transparent,
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              onDestinationSelected: (value) {
                if (searchIdx == value && _selectedTabIdx == value) {
                  // 如果点击的是探索页，且当前已在探索页，则进入聚合搜索页
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) {
                      return const AnimeClimbAllWebsite();
                    },
                  ));
                } else {
                  setState(() {
                    _selectedTabIdx = value;
                  });
                }
              },
              destinations: [
                for (var tab in _mainTabs)
                  NavigationDestination(
                    icon: Icon(tab.iconData),
                    selectedIcon: Icon(tab.selectedIconData ?? tab.iconData),
                    label: tab.name,
                  ),
              ]),
        ],
      ),
    );
  }

  _buildMainPage() {
    if (!enableAnimation) return _mainTabs[_selectedTabIdx].page;

    return PageTransitionSwitcher(
        transitionBuilder: (
          Widget child,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _mainTabs[_selectedTabIdx].page);
  }
}
