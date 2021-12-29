import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/anime_list_page.dart';
import 'package:flutter_test_future/pages/history_page.dart';
import 'package:flutter_test_future/pages/setting_page.dart';
import 'package:flutter_test_future/scaffolds/search.dart';
import 'package:scroll_bottom_navigation_bar/scroll_bottom_navigation_bar.dart';

class Tabs extends StatefulWidget {
  const Tabs({Key? key}) : super(key: key);

  @override
  _TabsState createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  final List<Widget> _list = [
    const AnimeListPage(),
    const HistoryPage(),
    const SettingPage(),
  ];
  final List _listName = ["动漫", "历史", "更多"];
  int _currentIndex = 0;
  final controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    List<List<Widget>> actions = [];
    for (int i = 0; i < _list.length; ++i) {
      // error: actions[i] = []; 因为最外面的List为空，需要添加元素：空的List
      actions.add([]);
    }
    actions[0].add(
      IconButton(
        onPressed: () async {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const Search(),
            ),
          );
        },
        icon: const Icon(Icons.search_outlined),
        color: Colors.black,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _listName[_currentIndex],
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: actions[_currentIndex],
      ),
      // body: _list[_currentIndex], // 原始方法
      body: ValueListenableBuilder<int>(
        valueListenable: controller.bottomNavigationBar.tabNotifier,
        builder: (context, tabIndex, child) => Snap(
          controller: controller.bottomNavigationBar,
          child: _list[_currentIndex],
        ),
      ),
      // body: IndexedStack(
      //   // 新方法，可以保持页面状态。注：从详细中改变标签返回无法实时更新
      //   index: _currentIndex,
      //   children: _list,
      // ),

      // bottomNavigationBar: SalomonBottomBar(
      //   currentIndex: _currentIndex,
      //   onTap: (int index) {
      //     setState(() => _currentIndex = index);
      //   },
      //   items: [
      //     // SalomonBottomBarItem(
      //     //     icon: const SizedBox(
      //     //       width: 50,
      //     //       child: Icon(Icons.book),
      //     //     ),
      //     //     title: const Text("动漫")),
      //     // SalomonBottomBarItem(
      //     //     icon: const SizedBox(
      //     //       width: 50,
      //     //       child: Icon(Icons.history_rounded),
      //     //     ),
      //     //     title: const Text("历史")),
      //     // SalomonBottomBarItem(
      //     //   icon: const SizedBox(width: 50, child: Icon(Icons.more_horiz)),
      //     //   title: const Text("更多"),
      //     // ),
      //     SalomonBottomBarItem(
      //         icon: const Icon(Icons.book), title: const Text("动漫")),
      //     SalomonBottomBarItem(
      //         icon: const Icon(Icons.history_rounded), title: const Text("历史")),
      //     SalomonBottomBarItem(
      //         icon: const Icon(Icons.more_horiz), title: const Text("更多")),
      //   ],
      // ),
      // bottomNavigationBar: ScrollBottomNavigationBar(
      //   controller: controller,
      //   currentIndex: _currentIndex,
      //   elevation: 0,
      //   backgroundColor: const Color.fromRGBO(254, 254, 254, 1),
      //   onTap: (int index) {
      //     setState(() {
      //       _currentIndex = index;
      //     });
      //   },
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.book),
      //       label: "a",
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.history_rounded),
      //       label: "b",
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.more_horiz),
      //       label: "c",
      //     ),
      //   ],
      // ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        // elevation: 0,
        backgroundColor: const Color.fromRGBO(254, 254, 254, 1),
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "动漫",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: "历史",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: "更多",
          ),
        ],
      ),
    );
  }
}
