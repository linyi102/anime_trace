import 'package:flutter/material.dart';
import 'package:flutter_tab_indicator_styler/flutter_tab_indicator_styler.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/pages/note_list/episode_note_list_page.dart';
import 'package:flutter_test_future/pages/note_list/rate_note_list_page.dart';
import 'package:flutter_test_future/pages/settings/image_path_setting.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../../models/note_filter.dart';
import '../../utils/sp_util.dart';

class NoteListPage extends StatefulWidget {
  const NoteListPage({Key? key}) : super(key: key);

  @override
  _NoteListPageState createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage>
    with SingleTickerProviderStateMixin {
  // tab
  late TabController _tabController;
  final List<String> _navs = ["每集", "评价"];
  NoteFilter noteFilter = NoteFilter();

  @override
  void initState() {
    super.initState();
    // 顶部tab控制器
    _tabController = TabController(
      initialIndex: SPUtil.getInt("lastNavIndexInNoteListPageNav",
          defaultValue: 0), // 设置初始index
      length: _navs.length,
      vsync: this,
    );
    // 添加监听器，记录最后一次的topTab的index
    _tabController.addListener(() {
      if (_tabController.index == _tabController.animation!.value) {
        SPUtil.setInt("lastNavIndexInNoteListPageNav", _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    //为了避免内存泄露，需要调用.dispose
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtil.getScaffoldBackgroundColor(),
      appBar: AppBar(
        title: const Text(
          "笔记",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          _buildSearchIconButton(setState),
          _buildImageSettingIconButton(),
        ],
        bottom: _buildTabBar(),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          EpisodeNoteListPage(noteFilter: noteFilter),
          RateNoteListPage(noteFilter: noteFilter)
        ],
      ),
    );
  }

  PreferredSize _buildTabBar() {
    return PreferredSize(
      // 默认情况下，要将标签栏与相同的标题栏高度对齐，可以使用常量kToolbarHeight
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Material(
        color: ThemeUtil.getAppBarBackgroundColor(),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            tabs: _navs
                .map((nav) => Tab(
                    child:
                        Text(nav, textScaleFactor: ThemeUtil.smallScaleFactor)))
                .toList(),
            controller: _tabController,
            // 居中，而不是靠左下
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            // 标签可以滑动，避免拥挤
            // isScrollable: true,
            labelPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            // 指示器长短和标签一样
            indicatorSize: TabBarIndicatorSize.label,
            // 第三方指示器样式
            indicator: MaterialIndicator(
                color: ThemeUtil.getPrimaryColor(),
                paintingStyle: PaintingStyle.fill),
          ),
        ),
      ),
    );
  }

  _buildImageSettingIconButton() {
    return PopupMenuButton(
      tooltip: "更多",
      icon: const Icon(Icons.more_vert),
      itemBuilder: (popupMenuContext) {
        bool showAllNoteGridImage = SpProfile.getShowAllNoteGridImage();
        return [
          PopupMenuItem(
              padding: const EdgeInsets.all(0),
              child: ListTile(
                style: ListTileStyle.drawer,
                leading: const Icon(Icons.image_outlined),
                title: const Text("图片设置"),
                onTap: () {
                  Navigator.push(context, FadeRoute(
                    builder: (context) {
                      return const ImagePathSetting();
                    },
                  )).then((dirChanged) {
                    Navigator.pop(popupMenuContext);
                    if (dirChanged) {
                      Log.info("修改了图片目录，更新状态");
                      setState(() {});
                    }
                  });
                },
              )),
          PopupMenuItem(
            padding: const EdgeInsets.all(0),
            child: ListTile(
              style: ListTileStyle.drawer,
              leading: const Icon(Icons.expand),
              title: showAllNoteGridImage
                  ? const Text("显示部分图片")
                  : const Text("显示所有图片"),
              onTap: () {
                SpProfile.setShowAllNoteGridImage(!showAllNoteGridImage);
                setState(() {});
                Navigator.pop(popupMenuContext);
              },
            ),
          ),
        ];
      },
    );
  }

  IconButton _buildSearchIconButton(setState) {
    var animeNameController = TextEditingController();
    var noteContentController = TextEditingController();

    return IconButton(
        tooltip: "搜索",
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("搜索"),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: animeNameController
                            ..text = noteFilter.animeNameKeyword,
                          decoration: InputDecoration(
                              labelText: "动漫关键字",
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                  onPressed: () {
                                    animeNameController.text = "";
                                  },
                                  icon: const Icon(Icons.close),
                                  iconSize: 18)),
                        ),
                        TextField(
                          controller: noteContentController
                            ..text = noteFilter.noteContentKeyword,
                          decoration: InputDecoration(
                              labelText: "笔记关键字",
                              helperText: "评价页暂不支持查询",
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                  onPressed: () {
                                    noteContentController.text = "";
                                  },
                                  icon: const Icon(Icons.close),
                                  iconSize: 18)),
                        )
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("取消")),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          noteFilter.animeNameKeyword =
                              animeNameController.text;
                          noteFilter.noteContentKeyword =
                              noteContentController.text;
                          setState(() {});
                          // setSatate后，子组件会执行didUpdateWidget
                        },
                        child: const Text("搜索")),
                  ],
                );
              });
        },
        icon: const Icon(Entypo.search));
  }
}
