import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_item_auto_load.dart';
import 'package:flutter_test_future/components/common_tab_bar.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/components/search_app_bar.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/site_collection_tab.dart';
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
  Climb get climb => widget.climbWebsite.climb;
  List<SiteCollectionTab> get siteCollectionTab => climb.siteCollectionTabs;

  late TabController tabController;
  List<bool> searching = [];
  List<UserCollection> userCollection = [];

  late String userId;
  TextEditingController inputController = TextEditingController();
  List<RefreshController> refreshControllers = [];

  @override
  void initState() {
    for (int i = 0; i < siteCollectionTab.length; ++i) {
      searching.add(false);
      userCollection.add(UserCollection(totalCnt: 0, animes: []));
      refreshControllers.add(RefreshController());
    }
    tabController = TabController(
      length: siteCollectionTab.length,
      vsync: this,
    );
    super.initState();
  }

  @override
  void dispose() {
    tabController.dispose();
    for (var refreshController in refreshControllers) {
      refreshController.dispose();
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

            // 有时查询有些慢，此时应该也显示加载圈
            for (int collIdx = 0;
                collIdx < siteCollectionTab.length;
                ++collIdx) {
              searching[collIdx] = true;
            }
            if (mounted) setState(() {});
            // 查询用户
            bool exist = await climb.existUser(userId);

            if (!exist) {
              showToast("不存在该用户");
              // 取消加载圈
              for (int collIdx = 0;
                  collIdx < siteCollectionTab.length;
                  ++collIdx) {
                searching[collIdx] = false;
              }
              if (mounted) setState(() {});
              return;
            }

            // 查询所有tab
            for (int i = 0; i < siteCollectionTab.length; ++i) {
              _onRefresh(i);
            }
          },
        ),
        bottom: CommonBottomTabBar(
          tabs: List.generate(
            siteCollectionTab.length,
            (collIdx) => Tab(
              text:
                  "${siteCollectionTab[collIdx].title} (${userCollection[collIdx].totalCnt})",
            ),
          ),
          tabController: tabController,
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: List.generate(siteCollectionTab.length, (collIdx) {
          if (searching[collIdx]) return loadingWidget(context);
          if (userCollection[collIdx].animes.isEmpty) return emptyDataHint();

          return SmartRefresher(
            controller: refreshControllers[collIdx],
            enablePullDown: true,
            enablePullUp: true,
            onRefresh: () => _onRefresh(collIdx),
            onLoading: () => _loadMore(collIdx),
            child: ListView.builder(
                itemCount: userCollection[collIdx].animes.length,
                itemBuilder: (context, animeIdx) {
                  Anime anime = userCollection[collIdx].animes[animeIdx];
                  return AnimeItemAutoLoad(
                    anime: anime,
                    climbDetail: false, // 过多会提示拒绝执行
                    subtitles: [
                      anime.nameAnother,
                      anime.tempInfo ?? "",
                    ],
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
    userCollection[collIdx].animes.clear();
    userCollection[collIdx].totalCnt = 0;
    if (mounted) setState(() {});

    // 不放在setState是为了避免mounted为false时，不会赋值数据
    var collection = siteCollectionTab[collIdx];
    userCollection[collIdx] =
        await climb.climbUserCollection(userId, collection);
    searching[collIdx] = false;
    if (mounted) setState(() {});
  }

  _loadMore(int collIdx) async {
    // 如果已查询的数量>=最大数量，则标记为没有更多数据了
    if (userCollection[collIdx].animes.length >=
        userCollection[collIdx].totalCnt) {
      refreshControllers[collIdx].loadNoData();
      return;
    }

    var newPageAnimes = (await climb.climbUserCollection(
      userId,
      siteCollectionTab[collIdx],
      // 每页x个，如果当前已查询了x个，那么x~/x=1，会再次查询第1页，因此最终要+1
      page:
          (userCollection[collIdx].animes.length ~/ climb.userCollPageSize) + 1,
    ))
        .animes;
    // 添加新增的动漫，不要重新赋值userCollection
    userCollection[collIdx].animes.addAll(newPageAnimes);
    if (mounted) setState(() {});
  }
}
