import 'dart:io';

import 'package:easy_sidemenu/easy_sidemenu.dart';
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
  ];
  final List<String> _tabNames = ["动漫", "网络", "历史", "笔记", "更多"];
  final List<IconData> _tabIconDatas = [
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
            icon: _tabIconDatas[i],
            label: _tabNames[i],
            onTap: () {
              _currentIndex = i;
              setState(() {});
            }),
      );
    }
    return sidebarXItems;
  }

  final _sidebarXController =
      SidebarXController(selectedIndex: 0, extended: true);

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
          // ? _buildSidebarX()
          ? _buildSideBar()
          : _buildBottomNavigationBar(),
    );
  }

  // 不能放到方法内部，否则选中的item颜色不会改变
  List<SideMenuItem> items = [];
  PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _tabNames.length; ++i) {
      items.add(
        SideMenuItem(
          // Priority of item to show on SideMenu, lower value is displayed at the top
          priority: i,
          title: "  ${_tabNames[i]}", // 添加空格，否则太靠近图标
          onTap: () => pageController.jumpToPage(i),
          icon: Icon(_tabIconDatas[i]),
        ),
      );
    }
  }

  // TODO：win端如果最初没有点击中间3个tab，切换夜间模式时会导致tav按钮和文字颜色没变，鼠标滑过后才会变化
  Scaffold _buildSideBar() {
    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 左侧显示侧边栏
          Obx(() => SideMenu(
                title: SizedBox(
                  height: 100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset('assets/images/logo.png'),
                  ),
                ),
                items: items,
                controller: pageController,
                style: SideMenuStyle(
                  displayMode: SideMenuDisplayMode.auto,
                  decoration: const BoxDecoration(),
                  openSideMenuWidth: 120,
                  compactSideMenuWidth: 60,
                  // hoverColor: Colors.blue[100],
                  // selectedColor: Colors.blue,
                  selectedIconColor: ThemeUtil.getIconButtonColor(),
                  unselectedIconColor: ThemeUtil.getIconButtonColor(),
                  backgroundColor: ThemeUtil.getSideBarBackgroundColor(),
                  selectedTitleTextStyle:
                      TextStyle(color: ThemeUtil.getFontColor()),
                  unselectedTitleTextStyle:
                      TextStyle(color: ThemeUtil.getFontColor()),
                ),
              )),
          // 右侧显示body
          Expanded(
              child: PageView(
            controller: pageController,
            children: _list,
          ))
        ],
      ),
    );
  }

  Scaffold _buildBottomNavigationBar() {
    return Scaffold(
      body: _list[_currentIndex],
      // body: IndexedStack(
      //   // 新方法，可以保持页面状态。注：历史和笔记页面无法同步更新
      //   index: _currentIndex,
      //   children: _list,
      // ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 当item数量超过3个，则会显示空白，此时需要设置该属性
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
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "更多"),
        ],
      ),
    );
  }

  Scaffold _buildSidebarX() {
    return Scaffold(
      body: Row(
        children: [
          Obx(() => SidebarX(
                showToggleButton: true,
                controller: _sidebarXController,
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
                footerDivider: const Divider(),
                // 展开时的主题
                extendedTheme: const SidebarXTheme(
                  width: 150,
                ),
                theme: SidebarXTheme(
                  // margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ThemeUtil.getSideBarBackgroundColor(),
                    // borderRadius: BorderRadius.circular(20),
                  ),
                  // 图标和标签的距离
                  itemTextPadding: const EdgeInsets.only(left: 30),
                  selectedItemTextPadding: const EdgeInsets.only(left: 30),
                  // itemPadding: EdgeInsets.only(top: 20),
                  // selectedItemPadding: EdgeInsets.only(top: 20),
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
    );
  }
}
