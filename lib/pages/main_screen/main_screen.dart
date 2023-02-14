import 'dart:io';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/my_icon_button.dart';
import 'package:flutter_test_future/pages/anime_collection/anime_list_page.dart';
import 'package:flutter_test_future/pages/history/history_page.dart';
import 'package:flutter_test_future/pages/network/network_page.dart';
import 'package:flutter_test_future/pages/note_list/note_list_page.dart';
import 'package:flutter_test_future/pages/settings/settings_page.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_test_future/utils/log.dart';

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

  bool showBottomBarLabel = true;
  bool expandSideBar = SpProfile.getExpandSideBar();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: clickTwiceToExitApp,
      // child: _buildBottomNavigationBar(),
      child: Platform.isAndroid &&
              MediaQuery.of(context).orientation == Orientation.portrait
          ? _buildBottomNavigationBar() // 手机竖向时显示底部栏
          : Scaffold(
              body: SafeArea(
                child: Row(
                  children: [
                    // 侧边栏
                    _buildSideBar(),
                    // 主体
                    Expanded(child: _mainTabs[_selectedTabIdx].page)
                  ],
                ),
              ),
            ),
    );
  }

  Future<bool> clickTwiceToExitApp() async {
    _clickBackCnt++;
    if (_clickBackCnt == 2) {
      return true;
    }
    Future.delayed(const Duration(seconds: 2)).then((value) {
      _clickBackCnt = 0;
      Log.info("点击返回次数重置为0");
    });
    showToast("再次点击退出应用");
    return false;
  }

  _buildSideBar() {
    return AnimatedContainer(
      width: expandSideBar ? 150 : 70,
      duration: const Duration(milliseconds: 200),
      child: Obx(() => Drawer(
            backgroundColor: ThemeUtil.getSideBarBackgroundColor(),
            // 缩小界面后可以滚动，防止溢出
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
          )),
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
        MaterialButton(
          padding: EdgeInsets.zero,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onPressed: () {
            _selectedTabIdx = i;
            setState(() {});
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).hoverColor.withAlpha(20)
                  : null,
              borderRadius: BorderRadius.circular(6),
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
    widgets.add(const Divider());
    widgets.add(Row(
      mainAxisAlignment:
          expandSideBar ? MainAxisAlignment.end : MainAxisAlignment.center,
      children: [
        MyIconButton(
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

  Scaffold _buildBottomNavigationBar() {
    return Scaffold(
      body: _mainTabs[_selectedTabIdx].page,
      // 会导致第一次打开App时有点慢
      // body: IndexedStack(
      //   // 新方法，可以保持页面状态。注：历史和笔记页面无法同步更新
      //   index: _currentIndex,
      //   children: _list,
      // ),
      bottomNavigationBar: Obx(() => SizedBox(
            height: showBottomBarLabel ? null : 45,
            child: BottomNavigationBar(
              // 不显示文字方法1
              selectedFontSize: showBottomBarLabel ? 14.0 : 0,
              // 不显示文字方法2
              // selectedFontSize: 12,
              // showSelectedLabels: false,
              // showUnselectedLabels: false,
              backgroundColor: ThemeUtil.getSideBarBackgroundColor(),
              type: BottomNavigationBarType.fixed,
              // 当item数量超过3个，则会显示空白，此时需要设置该属性
              currentIndex: _selectedTabIdx,
              // elevation: 0,
              // backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
              onTap: (int index) {
                setState(() {
                  _selectedTabIdx = index;
                });
              },
              items: [
                for (var tab in _mainTabs)
                  BottomNavigationBarItem(
                      icon: Icon(tab.iconData), label: tab.name)
              ],
            ),
          )),
    );
  }
}
