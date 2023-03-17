import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_item_auto_load.dart';
import 'package:flutter_test_future/components/common_tab_bar.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/components/search_app_bar.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/user_collection.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ImportCollectionPage extends StatefulWidget {
  const ImportCollectionPage({required this.climbWebsite, super.key});
  final ClimbWebsite climbWebsite;

  @override
  State<ImportCollectionPage> createState() => _ImportCollectionPagrState();
}

class _ImportCollectionPagrState extends State<ImportCollectionPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  List<bool> searching = [];
  Climb get climb => widget.climbWebsite.climb;
  List<UserCollection> get collections => climb.collections;
  List<List<Anime>> animeLists = [];
  List<int> totalCnts = [];

  late String userId;
  TextEditingController inputController = TextEditingController();
  List<RefreshController> refreshControllers = [
    RefreshController(),
    RefreshController(),
    RefreshController()
  ];

  @override
  void initState() {
    for (int i = 0; i < collections.length; ++i) {
      searching.add(false);
      animeLists.add([]);
      totalCnts.add(0);
    }
    tabController = TabController(
      length: collections.length,
      vsync: this,
    );
    super.initState();
  }

  @override
  void dispose() {
    tabController.dispose();
    for (var controller in refreshControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SearchAppBar(
          inputController: inputController,
          useModernStyle: false,
          hintText: "用户ID",
          isAppBar: false,
          onTapClear: () {
            inputController.clear();
          },
          onEditingComplete: () async {
            userId = inputController.text;
            if (userId.isEmpty) {
              showToast("用户ID不能为空");
              return;
            }

            bool exist = await climb.existUser(userId);
            if (!exist) {
              showToast("不存在该用户");
              return;
            }

            for (int i = 0; i < collections.length; ++i) {
              _onRefresh(i);
            }
          },
        ),
        bottom: CommonBottomTabBar(
          tabs: List.generate(
            collections.length,
            (collIdx) => Tab(
              text: "${collections[collIdx].title} (${totalCnts[collIdx]})",
            ),
          ),
          tabController: tabController,
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: List.generate(collections.length, (collIdx) {
          if (searching[collIdx]) return loadingWidget(context);
          if (animeLists[collIdx].isEmpty) return emptyDataHint();

          return SmartRefresher(
            controller: refreshControllers[collIdx],
            enablePullDown: true,
            enablePullUp: true,
            onRefresh: () => _onRefresh(collIdx),
            onLoading: () => _loadMore(collIdx),
            child: ListView.builder(
                itemCount: animeLists[collIdx].length,
                itemBuilder: (context, index) {
                  Anime anime = animeLists[collIdx][index];
                  return AnimeItemAutoLoad(
                    anime: anime,
                    climbDetail: false, // 过多会提示拒绝执行
                    showProgress: true,
                    onChanged: (newAnime) {
                      anime = newAnime;
                      if (mounted) setState(() {});
                    },
                  );
                }),
          );
        }),
      ),
    );
  }

  _onRefresh(int collIdx) async {
    // 重置数据
    searching[collIdx] = true;
    animeLists[collIdx].clear();
    totalCnts[collIdx] = 0;
    if (mounted) setState(() {});

    // 不放在setState是为了避免mounted为false时，不会赋值数据
    var collection = collections[collIdx];
    animeLists[collIdx] = await climb.climbUserCollection(userId, collection);
    totalCnts[collIdx] = await climb.climbUserCollectionCnt(userId, collection);
    searching[collIdx] = false;
    if (mounted) setState(() {});
  }

  _loadMore(int collIdx) async {
    // 如果已查询的数量>=最大数量，则标记为没有更多数据了
    if (animeLists[collIdx].length >= totalCnts[collIdx]) {
      refreshControllers[collIdx].loadNoData();
      return;
    }

    var collection = collections[collIdx];
    List<Anime> animes = await climb.climbUserCollection(
      userId,
      collection,
      page: animeLists[collIdx].length ~/ 15,
    );
    animeLists[collIdx].addAll(animes);
    if (mounted) setState(() {});
  }
}
