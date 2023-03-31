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
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
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
  List<bool> searching = []; // 每个tab对应是否正在查询用户收藏
  List<UserCollection> userCollection = [];
  bool addDBing = false; // 只允许对单个tab全部新增到数据库，此时不允许其他tab添加

  late String userId;
  TextEditingController inputController = TextEditingController();
  List<RefreshController> refreshControllers = [];
  int get curCollIdx => tabController.index;

  bool showTip = true; // 最初主体显示使用提示，搜索后显示查询结果

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
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(),
      floatingActionButton: showTip ? null : _buildFAB(context),
      body: showTip
          ? ListView(
              children: const [
                ListTile(
                  title: Text("这个可以做什么？"),
                  subtitle: Text(
                      "如果你之前在Bangumi或豆瓣中收藏过很多电影或动漫，该功能可以帮忙把这些数据导入到漫迹中，而不需要手动添加"),
                ),
                ListTile(
                  title: Text("如何获取用户ID？"),
                  subtitle: Text(
                      "在Bangumi中查看自己的信息时，访问的链接若为https://bangumi.tv/user/123456，那么该用户的ID就是123456"),
                ),
              ],
            )
          : Stack(
              children: [
                _buildTabBarView(context),
                // _buildBottomCollectButton(context)
              ],
            ),
    );
  }

  _buildTabBarView(BuildContext context) {
    return TabBarView(
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
          child: _buildAnimeListView(collIdx),
        );
      }),
    );
  }

  ListView _buildAnimeListView(int collIdx) {
    return ListView.builder(
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
        });
  }

  FloatingActionButton _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        if (userCollection[curCollIdx].totalCnt == 0) {
          showToast("没有收藏的动漫");
          return;
        }

        if (addDBing) {
          showToast("收藏中，请稍后再试");
          return;
        }

        _showBottomSelectChecklist(context, curCollIdx);
      },
      child: const Icon(EvaIcons.starOutline, color: Colors.white),
    );
  }

  _buildAppBar() {
    return AppBar(
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

          // 隐藏提示
          showTip = false;
          // 有时查询有些慢，此时应该也显示加载圈
          for (int collIdx = 0; collIdx < siteCollectionTab.length; ++collIdx) {
            searching[collIdx] = true;
          }
          if (mounted) setState(() {});
          // 查询用户
          bool exist = await climb.existUser(userId);

          if (!exist) {
            showToast("${climb.sourceName}中不存在该用户");
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
      bottom: showTip
          ? null
          : CommonBottomTabBar(
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
    );
  }

  /// 一键添加当前tab下的所有收藏
  /// 提示选择清单
  /// 注意要把curCollIdx作为参数传进来，避免加载更多时切换tab导致加载了其他tab动漫
  _showBottomSelectChecklist(BuildContext context, int collIdx) {
    final scrollController = ScrollController();

    return showCommonBottomSheet(
        context: context,
        expanded: true,
        title: Text("一键收藏 “${siteCollectionTab[collIdx].title}” 到"),
        child: Scrollbar(
          controller: scrollController,
          child: ListView.builder(
            controller: scrollController,
            itemCount: tags.length,
            itemBuilder: (context, index) {
              var tag = tags[index];

              return ListTile(
                  title: Text(tag),
                  onTap: () async {
                    // 关闭底部面板
                    Navigator.pop(context);

                    Log.info("collIdx=$collIdx");
                    showToast("收藏中");
                    addDBing = true;
                    if (mounted) setState(() {});

                    // 收藏该tab下的所有动漫
                    // 不断加载更多数据，直到没有更多数据或查询失败(即返回false)
                    while (await _loadMore(collIdx)) {}

                    int added = 0, // 数据库中已有
                        addFail = 0, // 添加失败
                        addOk = 0, // 添加成功
                        total = userCollection[collIdx].animes.length;
                    Log.info("当前tab已全部加载完毕，数量：$total");
                    for (var anime in userCollection[collIdx].animes) {
                      if ((await SqliteUtil.getAnimeByAnimeUrl(anime))
                          .isCollected()) {
                        added++;
                      } else {
                        // 如果数据库不存在，则指定清单，然后添加到数据库
                        anime.tagName = tag;
                        anime.animeId = await SqliteUtil.insertAnime(anime);
                        // 逐个添加到数据库
                        if (anime.animeId > 0) {
                          addOk++;
                        } else {
                          addFail++;
                        }
                      }
                    }
                    addDBing = false;
                    if (mounted) setState(() {});
                    String msg = "";
                    if (added > 0) msg += "$added个已跳过";
                    if (addOk > 0) {
                      if (msg.isNotEmpty) msg += "，";
                      msg += "$addOk个添加成功";
                    }
                    if (addFail > 0) {
                      if (msg.isNotEmpty) msg += "，";
                      msg += "$addFail个添加失败";
                    }
                    showToast(msg);
                    // showToast("$added个已跳过，$addOk个添加成功，$addFail个添加失败");
                  });
            },
          ),
        ));
  }

  _buildBottomCollectButton(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: InkWell(
        onTap: () {
          if (addDBing) {
            showToast("收藏中，请稍后再试");
            return;
          }

          _showBottomSelectChecklist(context, curCollIdx);
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
            // color: ThemeUtil.getPrimaryColor(),
            color: Colors.white,
            border: Border(
                top: BorderSide(
              color: Colors.grey,
            )),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "收藏「${siteCollectionTab[curCollIdx].title}」下的所有动漫",
                // style: const TextStyle(color: Colors.white),
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

    // 如果当前数量不够总数，那么就重置为可以加载
    // 可能之前已全部加载或加载完毕，因此需要重置
    if (userCollection[collIdx].animes.length <
        userCollection[collIdx].totalCnt) {
      refreshControllers[collIdx].loadComplete();
    } else if (userCollection[collIdx].animes.length <=
        userCollection[collIdx].totalCnt) {
      refreshControllers[collIdx].loadNoData();
    }
  }

  Future<bool> _loadMore(int collIdx) async {
    // 如果已查询的数量>=最大数量，则标记为没有更多数据了
    if (userCollection[collIdx].animes.length >=
        userCollection[collIdx].totalCnt) {
      refreshControllers[collIdx].loadNoData();
      return false;
    }

    // 每页x个，如果当前已查询了x个，那么x~/x=1，会再次查询第1页，因此最终要+1
    int page =
        (userCollection[collIdx].animes.length ~/ climb.userCollPageSize) + 1;
    Log.info("查询第$page页");
    var newPageAnimes = (await climb.climbUserCollection(
      userId,
      siteCollectionTab[collIdx],
      page: page,
    ))
        .animes;
    if (newPageAnimes.isNotEmpty) {
      // 添加新增的动漫，不要重新赋值userCollection
      userCollection[collIdx].animes.addAll(newPageAnimes);
      // 标记为获取完成，否则会一直显示加载，无法再次下拉加载更多
      refreshControllers[collIdx].loadComplete();
      if (mounted) setState(() {});
      return true;
    } else {
      // 如果为空，则说明加载失败
      refreshControllers[collIdx].loadFailed();
      return false;
    }
  }
}
