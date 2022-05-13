import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/anime_list_page.dart';
import 'package:flutter_test_future/pages/directory_page.dart';
import 'package:flutter_test_future/pages/history_page.dart';
import 'package:flutter_test_future/pages/note_list_page.dart';
import 'package:flutter_test_future/pages/setting_page.dart';
import 'package:flutter_test_future/utils/color_theme_util.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
// import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class Tabs extends StatefulWidget {
  const Tabs({Key? key}) : super(key: key);

  @override
  _TabsState createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  final List<Widget> _list = [
    const AnimeListPage(),
    const DirectoryPage(),
    const HistoryPage(),
    const NoteListPage(),
    const SettingPage(),
  ];
  int _currentIndex = 0;
  bool useSalomonBottomBar = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _list[_currentIndex],
      // body: IndexedStack(
      //   // 新方法，可以保持页面状态。注：历史和笔记页面无法同步更新
      //   index: _currentIndex,
      //   children: _list,
      // ),
      bottomNavigationBar: useSalomonBottomBar
          ? SalomonBottomBar(
              currentIndex: _currentIndex,
              onTap: (int index) {
                setState(() => _currentIndex = index);
              },
              items: [
                SalomonBottomBarItem(
                    icon: const Icon(Icons.home_filled),
                    title: const Text("动漫")),
                SalomonBottomBarItem(
                    icon: const Icon(Icons.book), title: const Text("目录")),
                SalomonBottomBarItem(
                    icon: const Icon(Icons.history_rounded),
                    title: const Text("历史")),
                SalomonBottomBarItem(
                    icon: const Icon(Icons.note_alt_outlined),
                    title: const Text("笔记")),
                SalomonBottomBarItem(
                    icon: const Icon(Icons.more_horiz),
                    title: const Text("更多")),
              ],
            )
          : BottomNavigationBar(
              backgroundColor: ColorThemeUtil.getScaffoldBackgroundColor(),
              selectedItemColor:
                  ColorThemeUtil.getBottomNaviBarSelectedItemColor(),
              unselectedItemColor:
                  ColorThemeUtil.getBottomNaviBarUnselectedItemColor(),
              type:
                  BottomNavigationBarType.fixed, // 当item数量超过3个，则会显示空白，此时需要设置该属性
              currentIndex: _currentIndex,
              // elevation: 0,
              // backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
              onTap: (int index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_filled), label: "动漫"),
                BottomNavigationBarItem(icon: Icon(Icons.book), label: "目录"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.history_rounded), label: "历史"),
                BottomNavigationBarItem(
                    // icon: Icon(Icons.note_alt_outlined),
                    icon: Icon(Icons.edit_road),
                    label: "笔记"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.more_horiz), label: "更多"),
              ],
            ),
    );
  }
}
