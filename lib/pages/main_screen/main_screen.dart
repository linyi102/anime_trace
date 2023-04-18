import 'dart:io';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/controllers/backup_service.dart';

import 'package:flutter_test_future/pages/anime_collection/anime_list_page.dart';
import 'package:flutter_test_future/pages/history/history_page.dart';
import 'package:flutter_test_future/pages/network/network_page.dart';
import 'package:flutter_test_future/pages/note_list/note_list_page.dart';
import 'package:flutter_test_future/pages/settings/settings_page.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/values/theme.dart';

class MainTab {
  String name;
  IconData iconData;
  Widget page;

  MainTab({required this.name, required this.iconData, required this.page});
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTabIdx = 0;
  int _clickBackCnt = 0;
  final List<MainTab> _mainTabs = [
    MainTab(name: "动漫", iconData: Icons.book, page: const AnimeListPage()),
    MainTab(
        name: "网络",
        iconData: Icons.local_library_outlined,
        page: const NetWorkPage()),
    MainTab(
        name: "历史", iconData: Icons.history_rounded, page: const HistoryPage()),
    MainTab(name: "笔记", iconData: Icons.edit_road, page: const NoteListPage()),
    MainTab(name: "更多", iconData: Icons.more_horiz, page: const SettingPage())
  ];

  bool expandSideBar = SpProfile.getExpandSideBar();
  double dividerThickness = 1;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: clickTwiceToExitApp,
      child: Platform.isAndroid &&
              MediaQuery.of(context).orientation == Orientation.portrait
          ? _buildPortraitScreen()
          : _buildLandscapeScreen(),
    );
  }

  Scaffold _buildLandscapeScreen() {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // 侧边栏
            _buildSideBar(),
            // VerticalDivider(width: dividerThickness),
            // 主体
            Expanded(child: _mainTabs[_selectedTabIdx].page)
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
        SystemNavigator.pop();
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
    return AnimatedContainer(
      width: expandSideBar ? 150 : 70,
      color: Theme.of(context).appBarTheme.backgroundColor,
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
    );
  }

  _buildSideMenu() {
    List<Widget> widgets = [];

    widgets.add(SizedBox(
      height: 100,
      child: DrawerHeader(
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
        child: Image.asset("assets/images/logo.png"),
      ),
    ));
    for (int i = 0; i < _mainTabs.length; ++i) {
      var mainTab = _mainTabs[i];

      bool isSelected = _selectedTabIdx == i;
      widgets.add(
        InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () {
            _selectedTabIdx = i;
            setState(() {});
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).focusColor : null,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
            margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
            child: Row(
                mainAxisAlignment: expandSideBar
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(mainTab.iconData),
                  // 使用Spacer而不是固定宽度，这样展开时文字就不会溢出的
                  if (expandSideBar) const Spacer(flex: 2),
                  if (expandSideBar)
                    Expanded(
                      flex: 4,
                      child: Text(
                        mainTab.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ]),
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
          icon: Icon(
            expandSideBar ? EvaIcons.arrowIosBack : EvaIcons.arrowIosForward,
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

  Scaffold _buildPortraitScreen() {
    return Scaffold(
      body: _mainTabs[_selectedTabIdx].page,
      bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedTabIdx,
          onDestinationSelected: (value) {
            setState(() {
              _selectedTabIdx = value;
            });
          },
          destinations: [
            for (var tab in _mainTabs)
              NavigationDestination(icon: Icon(tab.iconData), label: tab.name),
          ]),
    );
  }
}
