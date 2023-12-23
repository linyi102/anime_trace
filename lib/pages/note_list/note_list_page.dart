import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_tab_bar.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/note_filter.dart';
import 'package:flutter_test_future/pages/note_list/note_search_page.dart';
import 'package:flutter_test_future/pages/note_list/widgets/episode_note_list_page.dart';
import 'package:flutter_test_future/pages/note_list/widgets/rate_note_list_page.dart';
import 'package:flutter_test_future/pages/note_list/widgets/recently_create_note_anime_list_page.dart';
import 'package:flutter_test_future/routes/get_route.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/widgets/common_scaffold_body.dart';
import 'package:flutter_test_future/widgets/responsive.dart';

class NoteListPage extends StatefulWidget {
  const NoteListPage({Key? key}) : super(key: key);

  @override
  _NoteListPageState createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _navs = ["笔记", "评价"];

  NoteFilter noteFilter = NoteFilter();
  Anime? selectedAnime;

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
      appBar: AppBar(
        title: _buildTabBar(),
        actions: [
          _buildSearchIconButton(),
        ],
      ),
      body: CommonScaffoldBody(
        child: Responsive(
            mobile: _buildTabBarView(),
            tablet: _buildTabBarView(),
            desktop: Row(
              children: [
                Expanded(child: _buildTabBarView()),
                SizedBox(
                  width: 300,
                  child: RecentlyCreateNoteAnimeListPage(
                    selectedAnime: selectedAnime,
                    onTapItem: (anime) {
                      setState(() {
                        selectedAnime = anime;
                        noteFilter.animeNameKeyword = anime?.animeName ?? '';
                      });
                    },
                  ),
                )
              ],
            )),
      ),
    );
  }

  TabBarView _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        EpisodeNoteListPage(
          noteFilter: noteFilter,
          key: ValueKey('episode-note-${noteFilter.valueKeyStr}'),
        ),
        RateNoteListPage(
          noteFilter: noteFilter,
          key: ValueKey('rate-note-${noteFilter.valueKeyStr}'),
        )
      ],
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
