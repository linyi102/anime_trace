import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_item_auto_load.dart';
import 'package:flutter_test_future/components/bottom_sheet.dart';
import 'package:flutter_test_future/components/common_tab_bar.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/components/search_app_bar.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/site_collection_tab.dart';
import 'package:flutter_test_future/utils/climb/user_collection.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
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
          isScrollable: true,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 一键添加当前tab下的所有收藏
          // 提示选择清单
          showCommonBottomSheet(
              context: context,
              expanded: true,
              title: const Text("选择清单"),
              child: ListView.builder(
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  var tag = tags[index];

                  return ListTile(
                    title: Text(tag),
                    onTap: () {
                      // 关闭底部面板
                      Navigator.pop(context);
                      // 收藏该tab下的所有动漫
                    },
                  );
                },
              ));
        },
        child: const Icon(EvaIcons.starOutline, color: Colors.white),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: tabController,
            children: List.generate(siteCollectionTab.length, (collIdx) {
              if (searching[collIdx]) return loadingWidget(context);
              if (userCollection[collIdx].animes.isEmpty) {
                return emptyDataHint();
              }

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
                        climbDetail: false, // 频繁爬取会导致豆瓣提示拒绝执行
                        subtitles: [
                          anime.nameAnother,
                          anime.tempInfo ?? "",
                        ],
                        showProgress: false,
                        onChanged: (newAnime) {
                          anime = newAnime;
                          if (mounted) setState(() {});
                        },
                      );
                    }),
              );
            }),
          ),
          // _buildBottomCollectButton(context)
        ],
      ),
    );
  }

  Align _buildBottomCollectButton(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: InkWell(
        onTap: () {},
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: ThemeUtil.getPrimaryColor(),
            // border: Border.all(),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                "一键收藏",
                style: TextStyle(color: Colors.white),
              )
            ],
          ),
        ),
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
    if (newPageAnimes.isNotEmpty) {
      // 添加新增的动漫，不要重新赋值userCollection
      userCollection[collIdx].animes.addAll(newPageAnimes);
      // 标记为获取完成，否则会一直显示加载，无法再次下拉加载更多
      refreshControllers[collIdx].loadComplete();
      if (mounted) setState(() {});
    } else {
      // 如果为空，则说明加载失败
      refreshControllers[collIdx].loadFailed();
    }
  }
}
