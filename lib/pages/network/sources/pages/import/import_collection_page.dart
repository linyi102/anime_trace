import 'package:flutter/material.dart';
import 'package:animetrace/components/anime_item_auto_load.dart';
import 'package:animetrace/components/common_tab_bar.dart';
import 'package:animetrace/components/empty_data_hint.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/components/search_app_bar.dart';
import 'package:animetrace/components/website_logo.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/climb_website.dart';
import 'package:animetrace/pages/anime_collection/checklist_controller.dart';
import 'package:animetrace/pages/network/sources/pages/import/import_collection_controller.dart';
import 'package:animetrace/utils/climb/climb.dart';
import 'package:animetrace/utils/climb/site_collection_tab.dart';
import 'package:animetrace/utils/extensions/color.dart';
import 'package:animetrace/utils/sp_profile.dart';
import 'package:animetrace/utils/time_util.dart';
import 'package:animetrace/widgets/bottom_sheet.dart';
import 'package:animetrace/widgets/common_divider.dart';
import 'package:animetrace/widgets/common_tab_bar_view.dart';
import 'package:get/get.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:timer_count_down/timer_count_down.dart';

class ImportCollectionPage extends StatefulWidget {
  const ImportCollectionPage({required this.climbWebsite, super.key});
  final ClimbWebsite climbWebsite;

  @override
  State<ImportCollectionPage> createState() => _ImportCollectionPagrState();
}

/// 必须使用有状态组件，因为要TabController要使用SingleTickerProviderStateMixin里的this
class _ImportCollectionPagrState extends State<ImportCollectionPage>
    with SingleTickerProviderStateMixin {
  late ImportCollectionController icc;
  List<String> get tags => ChecklistController.to.tags;

  String get getxTag => widget.climbWebsite.name;
  int get curCollIdx => icc.tabController!.index;
  ClimbWebsite get climbWebsite => icc.climbWebsite;
  Climb get climb => icc.climbWebsite.climb;
  List<SiteCollectionTab> get siteCollectionTab =>
      icc.climbWebsite.climb.siteCollectionTabs;

  @override
  void initState() {
    icc =
        Get.put(ImportCollectionController(widget.climbWebsite), tag: getxTag);

    icc.tabController ??= TabController(
      length: siteCollectionTab.length,
      vsync: this,
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(),
      body: GetBuilder(
        id: ImportCollectionController.bodyId,
        tag: getxTag,
        init: icc,
        builder: (_) => _buildBody(),
      ),
    );
  }

  _buildBody() {
    if (icc.showTip) {
      return ListView(
        children: [
          ListTile(
            leading: WebSiteLogo(url: climbWebsite.iconUrl, size: 25),
            title: Text(climbWebsite.name),
          ),
          const ListTile(
            title: Text("这个可以做什么？"),
            subtitle:
                Text("如果你之前在Bangumi或豆瓣中收藏过很多电影或动漫，该功能可以帮忙把这些数据导入到漫迹中，而不需要手动添加"),
          ),
          const ListTile(
            title: Text("如何获取用户ID？"),
            subtitle: Text(
                "在Bangumi中查看自己的信息时，访问的链接若为https://bangumi.tv/user/123456，那么该用户的ID就是123456"),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (!icc.showTip) _buildTabBar(),
        Expanded(child: _buildTabBarView(context)),
        const CommonDivider(),
        _buildBottomBar(context)
      ],
    );
  }

  _buildTabBar() {
    return CommonBottomTabBar(
      bgColor: Theme.of(context).appBarTheme.backgroundColor,
      isScrollable: true,
      tabs: List.generate(
        siteCollectionTab.length,
        (collIdx) => Tab(
          text:
              "${siteCollectionTab[collIdx].title} (${icc.userCollection[collIdx].totalCnt})",
        ),
      ),
      tabController: icc.tabController,
    );
  }

  _buildTabBarView(BuildContext context) {
    return CommonTabBarView(
      controller: icc.tabController,
      children: List.generate(siteCollectionTab.length, (collIdx) {
        if (icc.searching[collIdx]) return loadingWidget(context);
        if (icc.userCollection[collIdx].animes.isEmpty) {
          return emptyDataHint(msg: "没有收藏。");
        }

        return SmartRefresher(
          controller: icc.refreshControllers[collIdx],
          enablePullDown: true,
          enablePullUp: true,
          onRefresh: () => icc.onRefresh(collIdx),
          onLoading: () => icc.loadMore(collIdx),
          child: _buildAnimeListView(collIdx),
        );
      }),
    );
  }

  ListView _buildAnimeListView(int collIdx) {
    return ListView.builder(
        itemCount: icc.userCollection[collIdx].animes.length,
        itemBuilder: (context, animeIdx) {
          Anime anime = icc.userCollection[collIdx].animes[animeIdx];
          return _buildAnimeItem(anime);
        });
  }

  _buildAppBar() {
    return AppBar(
      title: SearchAppBar(
        inputController: icc.inputController,
        hintText: "用户ID",
        isAppBar: false,
        autofocus: icc.showTip, // 如果显示提示，则自动聚焦输入框
        onTapClear: () {
          icc.inputController.clear();
        },
        onEditingComplete: () => icc.onEditingComplete(),
      ),
    );
  }

  /// 一键添加当前tab下的所有收藏
  /// 提示选择清单
  /// 注意要把curCollIdx作为参数传进来，避免加载更多时切换tab导致加载了其他tab动漫
  _showBottomSelectChecklist(BuildContext context, int collIdx) {
    if (icc.userCollection[curCollIdx].totalCnt == 0) {
      ToastUtil.showText("没有收藏的动漫");
      return;
    }

    if (icc.quickCollecting) {
      ToastUtil.showText("收藏中，请稍后再试");
      return;
    }

    final scrollController = ScrollController();

    showCommonModalBottomSheet(
        context: context,
        builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text("收藏 “${siteCollectionTab[collIdx].title}” 到"),
                automaticallyImplyLeading: false,
              ),
              body: Column(
                children: [
                  Expanded(
                    child: Scrollbar(
                      controller: scrollController,
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: tags.length,
                        itemBuilder: (context, index) {
                          var tag = tags[index];

                          return ListTile(
                              title: Text(tag),
                              onTap: () =>
                                  icc.quickCollect(context, collIdx, tag));
                        },
                      ),
                    ),
                  ),
                  const CommonDivider(),
                  StatefulBuilder(
                    builder: (context, setState) => SwitchListTile(
                      title: const Text("若已收藏同名动漫，则跳过"),
                      value: SpProfile.getSkipDupNameAnime(),
                      onChanged: (value) {
                        SpProfile.setSkipDupNameAnime(value);
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ));
  }

  _buildBottomBar(BuildContext context) {
    return GetBuilder(
        tag: getxTag,
        id: ImportCollectionController.bottomBarId,
        init: icc,
        builder: (_) {
          // 剩余页数/页大小，每页预计耗时6s(1s获取 + 5s间隔)
          int seconds =
              (icc.totalPage - icc.curPage + 1) * (icc.gap.inSeconds + 1);

          // 如果收藏完毕，应该还要显示进度，而不是收藏按钮，所以就不需要最初只显示收藏按钮了
          // return const OperationButton(text: "收藏");

          const textStyle = TextStyle(height: 1.2);
          return ListTile(
            leading: _buildBottomBarWebsiteIcon(),
            title: Text.rich(TextSpan(children: [
              TextSpan(text: "页数 ${icc.curPage}/${icc.totalPage}"),
              if (icc.quickCollecting)
                TextSpan(style: textStyle, children: [
                  const TextSpan(text: "，预计 "),
                  WidgetSpan(
                      child: Countdown(
                    seconds: seconds,
                    build: (context, value) => Text(
                      TimeUtil.getReadableDuration(
                        Duration(seconds: value.toInt()),
                      ),
                      style: textStyle,
                    ),
                  )),
                ]),
              const TextSpan(text: "\n"),
              TextSpan(
                  text: "成功 ${icc.addOk}，跳过 ${icc.added}，失败 ${icc.addFail}")
            ])),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (icc.addFail > 0)
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _buildFailedAnimeList(),
                            ));
                      },
                      child: const Text("查看失败")),
                icc.quickCollecting
                    ? icc.stopping
                        ? const Text("取消中")
                        : TextButton(
                            onPressed: () => icc.cancelQuickCollect(context),
                            child: const Text("取消"))
                    : OutlinedButton(
                        onPressed: () =>
                            _showBottomSelectChecklist(context, curCollIdx),
                        child: const Text("收藏")),
              ],
            ),
          );
        });
  }

  SizedBox _buildBottomBarWebsiteIcon() {
    const double size = 30;

    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        children: [
          // if (icc.quickCollecting)
          SizedBox(
            height: size,
            width: size,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacityFactor(0.3),
            ),
          ),
          WebSiteLogo(url: climbWebsite.iconUrl, size: size)
        ],
      ),
    );
  }

  Scaffold _buildFailedAnimeList() {
    return Scaffold(
        appBar: AppBar(title: const Text("失败列表")),
        body: ListView.builder(
            itemCount: icc.failedAnimes.length,
            itemBuilder: (context, animeIdx) {
              Anime anime = icc.failedAnimes[animeIdx];
              return _buildAnimeItem(anime);
            }));
  }

  AnimeItemAutoLoad _buildAnimeItem(Anime anime) {
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
  }
}
