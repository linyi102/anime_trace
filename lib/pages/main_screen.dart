import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/responsive.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:oktoast/oktoast.dart';

import 'home_tabs/anime_list_page.dart';
import 'home_tabs/history_page.dart';
import 'home_tabs/network_page.dart';
import 'home_tabs/note_list_page.dart';
import 'home_tabs/setting_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: clickTwiceToExitApp,
      child: Platform.isAndroid &&
              MediaQuery.of(context).orientation == Orientation.portrait
          ? _buildBottomNavigationBar() // 手机竖向时显示底部栏
          : Scaffold(
              body: SafeArea(
                child: Row(
                  children: [
                    // 展开侧边栏时，占1/6，如果不展开侧边栏，则固定宽度
                    size.width > 800
                        ? Expanded(child: _buildSideBar())
                        : SizedBox(
                            width: 60,
                            child: _buildSideBar(expandSideBar: false)),
                    // 主体 5/6
                    Expanded(flex: 5, child: _mainTabs[_selectedTabIdx].page)
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
        debugPrint("点击返回次数重置为0");
      });
      showToast("再次点击退出应用");
      return false;
    }

  Drawer _buildSideBar({bool expandSideBar = true}) {
    return Drawer(
      backgroundColor: ThemeUtil.getSideBarBackgroundColor(),
      // 缩小界面后可以滚动，防止溢出
      child: SingleChildScrollView(
        child: Column(
          children: _buildSideMenu(expandSideBar: expandSideBar),
        ),
      ),
    );
  }

  _buildSideMenu({bool expandSideBar = true}) {
    List<Widget> widgets = [];

    widgets.add(SizedBox(
      height: expandSideBar ? 120 : 60,
      // 手机横屏时，图片很占空间
      child: DrawerHeader(
          padding: const EdgeInsets.all(0),
          child: Transform.scale(
              scale: 0.8, child: Image.asset("assets/images/logo.png")
              // ListTile(
              //     title: const Icon(Icons.menu),
              //     onTap: () {
              //       expandSideBar = true;
              //       setState(() {});
              //     }),
              )),
    ));
    for (int i = 0; i < _mainTabs.length; ++i) {
      var mainTab = _mainTabs[i];
      widgets.add(ListTile(
        // 图标和标题距离
        // horizontalTitleGap: 0,
        selected: _selectedTabIdx == i,
        enableFeedback: false,
        title: expandSideBar
            ? Text(
                mainTab.name,
                textScaleFactor: 0.9,
              )
            : Icon(mainTab.iconData, size: 20),
        leading: expandSideBar ? Icon(mainTab.iconData, size: 20) : null,
        onTap: () {
          _selectedTabIdx = i;
          setState(() {});
        },
      ));
    }

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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 当item数量超过3个，则会显示空白，此时需要设置该属性
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
            BottomNavigationBarItem(icon: Icon(tab.iconData), label: tab.name)
        ],
      ),
    );
  }
}
