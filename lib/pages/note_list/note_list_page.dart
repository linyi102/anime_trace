import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_tab_bar.dart';
import 'package:flutter_test_future/models/note_filter.dart';
import 'package:flutter_test_future/pages/note_list/note_search_page.dart';
import 'package:flutter_test_future/pages/note_list/widgets/episode_note_list_page.dart';
import 'package:flutter_test_future/pages/note_list/widgets/rate_note_list_page.dart';
import 'package:flutter_test_future/routes/get_route.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/widgets/common_scaffold_body.dart';

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
  final bool _showSearchField = false;

  @override
  void initState() {
    super.initState();
    // 顶部tab控制器
    _tabController = TabController(
      initialIndex:
          SPUtil.getInt("lastNavIndexInNoteListPageNav", defaultValue: 0),
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
              ],
            ),
      body: CommonScaffoldBody(
        child: TabBarView(
          controller: _tabController,
          children: [
            EpisodeNoteListPage(noteFilter: noteFilter),
            RateNoteListPage(noteFilter: noteFilter)
          ],
        ),
      ),
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
  }

  _buildSearchIconButton() {
    return IconButton(
        onPressed: () {
          RouteUtil.materialTo(context, const NoteSearchPage());
        },
        icon: const Icon(Icons.search));
  }
}
