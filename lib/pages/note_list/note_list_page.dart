import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_tab_bar.dart';
import 'package:flutter_test_future/components/my_icon_button.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/models/note_filter.dart';
import 'package:flutter_test_future/pages/note_list/widgets/episode_note_list_page.dart';
import 'package:flutter_test_future/pages/note_list/widgets/rate_note_list_page.dart';
import 'package:flutter_test_future/pages/settings/image_path_setting.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/log.dart';

class NoteListPage extends StatefulWidget {
  const NoteListPage({Key? key}) : super(key: key);

  @override
  _NoteListPageState createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage>
    with SingleTickerProviderStateMixin {
  // tab
  late TabController _tabController;
  final List<String> _navs = ["笔记", "评价"];
  NoteFilter noteFilter = NoteFilter();

  // 输入框
  bool _showSearchField = false;

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
      appBar: _showSearchField
          ? _buildSearchField()
          : AppBar(
              title: _buildTabBar(),
              actions: [
                _buildSearchIconButton(),
                _buildImageSettingIconButton(),
              ],
              // bottom: _buildTabBar(),
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

  _buildSearchAppBar() {
    return AppBar(
      leading: MyIconButton(
        onPressed: () {
          setState(() {
            _showSearchField = false;
          });
        },
        icon: const Icon(Icons.arrow_back),
      ),
      title: _buildSearchField(),
      // actions: [
      //   InkWell(
      //     onTap: () {},
      //     child: Container(width: 50, child: Center(child: Text("搜索"))),
      //   ),
      // ],
    );
  }

  _buildSearchField() {
    var inputKeywordController = TextEditingController();

    return TextField(
      controller: inputKeywordController,
      decoration: const InputDecoration(
        hintText: "搜索笔记",
        prefixIcon: Icon(Icons.search),
        contentPadding: EdgeInsets.all(0),
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.all(Radius.circular(100)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.all(Radius.circular(100)),
        ),
      ),
    );
  }

  _buildTabBar() {
    return CommonTitleTabBar(
      tabs: _navs.map((nav) => Tab(child: Text(nav))).toList(),
      tabController: _tabController,
    );
    // return CommonTabBar(
    //   tabs: _navs
    //       .map((nav) => Tab(
    //           child: Text(nav, textScaleFactor: AppTheme.smallScaleFactor)))
    //       .toList(),
    //   controller: _tabController,
    // );
  }

  _buildImageSettingIconButton() {
    return PopupMenuButton(
      position: PopupMenuPosition.under,
      icon: const Icon(Icons.more_vert),
      itemBuilder: (popupMenuContext) {
        bool showAllNoteGridImage = SpProfile.getShowAllNoteGridImage();
        return [
          PopupMenuItem(
              padding: const EdgeInsets.all(0),
              child: ListTile(
                hoverColor: Colors.transparent,
                title: const Text("图片设置"),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) {
                      return const ImagePathSetting();
                    },
                  )).then((dirChanged) {
                    Navigator.pop(popupMenuContext);
                    if (Global.modifiedImgRootPath) {
                      Log.info("修改了图片或封面目录，更新状态，确保图片或封面可以及时正常显示");
                      setState(() {});
                      Global.modifiedImgRootPath = false;
                    }
                  });
                },
              )),
          PopupMenuItem(
            padding: const EdgeInsets.all(0),
            child: ListTile(
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

  _buildSearchIconButton() {
    var animeNameController = TextEditingController();
    var noteContentController = TextEditingController();

    // return MyIconButton(
    //     onPressed: () {
    //       // appbar显示输入框
    //       setState(() {
    //         _showSearchField = true;
    //       });
    //     },
    //     icon: const Icon(Icons.search));

    return MyIconButton(
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
                              suffixIcon: MyIconButton(
                                onPressed: () {
                                  animeNameController.text = "";
                                },
                                icon: const Icon(Icons.close, size: 18),
                              )),
                        ),
                        TextField(
                          controller: noteContentController
                            ..text = noteFilter.noteContentKeyword,
                          decoration: InputDecoration(
                              labelText: "笔记关键字",
                              helperText: "评价页暂不支持查询",
                              suffixIcon: MyIconButton(
                                onPressed: () {
                                  noteContentController.text = "";
                                },
                                icon: const Icon(Icons.close, size: 18),
                              )),
                        )
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("取消")),
                    TextButton(
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
        icon: const Icon(Icons.search));
  }
}
