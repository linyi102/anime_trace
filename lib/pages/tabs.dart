import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/anime_list_page.dart';
import 'package:flutter_test_future/pages/history_page.dart';
import 'package:flutter_test_future/pages/network/network_nav.dart';
import 'package:flutter_test_future/pages/note_list_page.dart';
import 'package:flutter_test_future/pages/setting_page.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sidebarx/sidebarx.dart';

class Tabs extends StatefulWidget {
  const Tabs({Key? key}) : super(key: key);

  @override
  _TabsState createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  final List<Widget> _list = [
    const AnimeListPage(),
    const NetWorkNav(),
    const HistoryPage(),
    const NoteListPage(),
    const SettingPage(),
    // const SettingPageTest()
  ];
  final List<String> _names = ["动漫", "网络", "历史", "笔记", "更多"];
  final List<IconData> iconDatas = [
    Icons.book,
    Icons.local_library_outlined,
    Icons.history_rounded,
    Icons.edit_road,
    Icons.more_horiz,
  ];
  int _currentIndex = 0;
  int _clickBackCnt = 0;

  List<SidebarXItem> _buildSidebarXItem() {
    List<SidebarXItem> sidebarXItems = [];
    for (int i = 0; i < _list.length; ++i) {
      sidebarXItems.add(
        SidebarXItem(
            icon: iconDatas[i],
            label: _names[i],
            onTap: () {
              _currentIndex = i;
              setState(() {});
            }),
      );
    }
    return sidebarXItems;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
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
      },
      child: Platform.isWindows
          ? Scaffold(
              body: Row(
                children: [
                  Obx(() => SidebarX(
                        showToggleButton: false,
                        // 不显示展开按钮
                        controller:
                            SidebarXController(selectedIndex: _currentIndex),
                        items: _buildSidebarXItem(),
                        animationDuration: const Duration(milliseconds: 200),
                        headerBuilder: (context, extended) {
                          return SizedBox(
                            height: 100,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Image.asset('assets/images/logo.png'),
                            ),
                          );
                        },
                        extendedTheme: const SidebarXTheme(
                          textStyle: TextStyle(color: Colors.black),
                          width: 200,
                        ),
                        theme: SidebarXTheme(
                          selectedItemDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: ThemeUtil.getSideBarSelectedItemColor(),
                          ),
                        ),
                      )),
                  // 必须要用Expanded
                  Expanded(child: _list[_currentIndex])
                ],
              ),
            )
          : Scaffold(
              body: _list[_currentIndex],
              // body: IndexedStack(
              //   // 新方法，可以保持页面状态。注：历史和笔记页面无法同步更新
              //   index: _currentIndex,
              //   children: _list,
              // ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType
                    .fixed, // 当item数量超过3个，则会显示空白，此时需要设置该属性
                currentIndex: _currentIndex,
                // elevation: 0,
                // backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
                onTap: (int index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.book), label: "动漫"),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.local_library_outlined), label: "网络"),
                  // icon: Icon(Entypo.network),
                  // label: "网络"),
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
            ),
    );
  }
}
