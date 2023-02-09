import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/classic_refresh_style.dart';
import 'package:flutter_test_future/components/refresher_footer.dart';
import 'package:flutter_test_future/components/website_logo.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_checklist.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/models/climb_website.dart';

import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/climb_quqi.dart';
import 'package:flutter_test_future/utils/climb/climb_yhdm.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class DirectoryPage extends StatefulWidget {
  const DirectoryPage({Key? key}) : super(key: key);

  @override
  State<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // 页大小是固定24个，不管设置多少都始终会获取24个动漫
  // 这里设置是为了方便加载更多数据
  PageParams pageParams = PageParams(pageIndex: 0, pageSize: 24);

  final ScrollController _scrollController = ScrollController();

  late ClimbWebsite curWebsite;

  final List<Climb> usableClimbs = [ClimbQuqi(), ClimbYhdm()];

  late final RefreshController _refreshController;

  final _itemHeight = 120.0;
  final _coverWidth = 80.0;

  @override
  void initState() {
    super.initState();

    // 默认为可用列表中的第一个，然后从所有搜索源中找到对应的下标
    int defaultIdx = climbWebsites.indexWhere((element) =>
        element.climb.runtimeType == usableClimbs.first.runtimeType);
    int websiteIdx =
        SPUtil.getInt(selectedDirectorySourceIdx, defaultValue: defaultIdx);
    if (websiteIdx > climbWebsites.length) {
      websiteIdx = defaultIdx;
    } else {
      curWebsite = climbWebsites[websiteIdx];
    }

    if (directory.isEmpty) {
      // 如果目录为空，则设置刷新控制器需要首次刷新
      _refreshController = RefreshController(initialRefresh: true);
      // 而不再手动加载数据
      // _loadData();
    } else {
      _refreshController = RefreshController(initialRefresh: false);
      // 如果已有数据，则直接显示，但也要根据重新查询数据库中的动漫来替换
      _replaceDbAnimes();
    }
  }

  @override
  void dispose() {
    super.dispose();
    //为了避免内存泄露，需要调用.dispose
    _scrollController.dispose();
  }

  // 从聚合搜索页返回后需要用到。不过目前用不到了，因为搜索按钮在network_nav中，无法直接处理目录页中的数据。并不影响，如果在聚合搜索页中添加了某个动漫，然后再从目录页中添加动漫，则会添加两个动漫
  // 切换到目录页也会用到
  void _replaceDbAnimes() async {
    // 即使查询过了，也需要查询数据库中的动漫，因为可能会已经取消收藏了
    for (int i = 0; i < directory.length; ++i) {
      directory[i] = await SqliteUtil.getAnimeByAnimeUrl(directory[i]);
    }
    setState(() {});
  }

  // 不要手动调用，而是通过_refreshController.requestRefresh()，这样可以有刷新效果
  void _loadData() async {
    pageParams.resetPageIndex(); // 更改条件后，需要重置页号
    directory = await curWebsite.climb.climbDirectory(filter, pageParams);
    Log.info("目录页：数据获取完毕");
    // 根据动漫名和来源查询动漫，如果存在
    // 则获取到id(用于进入详细页)和tagName(用于修改tag)
    // 下面两种方式修改了anime，都不能修改数组中的值
    // 1. for (var anime in directory) {
    // 2. for (int i = 0; i < directory.length; ++i) {
    //   Anime anime = directory[i];
    for (int i = 0; i < directory.length; ++i) {
      directory[i] = await SqliteUtil.getAnimeByAnimeUrl(directory[i]);
    }
    if (mounted) {
      setState(() {});
    }
    // 更改为刷新完成状态
    _refreshController.refreshCompleted();
    // 切换过滤条件后会重新加载数据，因此这里要把footer设置为idle，否则如果之前到底了，然后再切换过滤条件，则仍显示的是到底状态
    _refreshController.loadComplete();
  }

  _loadMoreData() async {
    Log.info("目录页：加载更多数据中，当前动漫数量：${directory.length}");
    pageParams.pageIndex++;
    int startIdx = directory.length;

    var moreAnimes = await curWebsite.climb.climbDirectory(filter, pageParams);
    if (moreAnimes.isEmpty) {
      Log.info("目录页：没有更多数据了");
      _refreshController.loadNoData();
    } else {
      Log.info("目录页：加载更多数据完毕，当前动漫数量：${directory.length}");
      directory.addAll(moreAnimes);
      for (int i = startIdx; i < directory.length; ++i) {
        directory[i] = await SqliteUtil.getAnimeByAnimeUrl(directory[i]);
      }
      if (mounted) {
        setState(() {});
      }
      _refreshController.loadComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Scrollbar(
        controller: _scrollController,
        // Scrollbar嵌套SmartRefresher，反过来无法下拉刷新
        child: SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          enablePullUp: true,
          onRefresh: _loadData,
          onLoading: _loadMoreData,
          // header: MaterialClassicHeader(
          //   color: ThemeUtil.getPrimaryColor(),
          //   backgroundColor: ThemeUtil.getCardColor(),
          // ),
          header: const MyClassicHeader(),
          footer: const MyClassicFooter(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverList(
                  delegate: SliverChildListDelegate([
                // _buildSourceTile(),
                _buildFilter(),
              ])),
              _buildAnimeSliverList(),
            ],
          ),
        ),
      ),
    );
  }

  // 构建当前搜索源
  _buildSourceTile() {
    return ListTile(
      title: Row(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WebSiteLogo(url: curWebsite.iconUrl, size: 25),
          const SizedBox(width: 10),
          Text(curWebsite.name),
        ],
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            children: climbWebsites.map((e) {
              if (e.discard) return Container();

              // 如果该搜索源e的climb工具在usableClimbs中，则显示可用
              bool usable = usableClimbs.indexWhere(
                    (element) => element.runtimeType == e.climb.runtimeType,
                  ) >=
                  0;
              return ListTile(
                title: Text(
                  e.name,
                  style: usable ? null : const TextStyle(color: Colors.grey),
                ),
                leading: WebSiteLogo(url: e.iconUrl, size: 25),
                trailing:
                    e.name == curWebsite.name ? const Icon(Icons.check) : null,
                enabled: usable,
                onTap: () {
                  curWebsite = e;
                  SPUtil.setInt(selectedDirectorySourceIdx,
                      climbWebsites.indexWhere((element) => element == e));

                  _refreshController.requestRefresh();
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  SliverList _buildAnimeSliverList() {
    // if (directory.isEmpty) {
    //   return SliverList(
    //       delegate: SliverChildListDelegate([emptyDataHint("什么都没找到")]));
    // }
    return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
      // Log.info("index=$index, pageParams.getQueriedSize()=${pageParams.getQueriedSize()}");
      // if (index + 5 == pageParams.getQueriedSize()) _loadMoreData();

      Anime anime = directory[index];
      final imageProvider = Image.network(anime.animeCoverUrl).image;
      return SizedBox(
        height: _itemHeight,
        child: MaterialButton(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          onPressed: () {
            Log.info("单击");
            // 如果收藏了，则单击进入详细页面
            if (anime.isCollected()) {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return AnimeDetailPlus(anime);
              })).then((value) {
                setState(() {
                  // anime = value;
                  directory[index] = value;
                });
              });
            } else {
              showToast("收藏后即可进入详细页面");
            }
          },
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: MaterialButton(
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => PhotoView(
                              imageProvider: imageProvider,
                              onTapDown: (_, __, ___) =>
                                  Navigator.of(context).pop())));
                    },
                    child: SizedBox(
                        width: _coverWidth,
                        child: AnimeGridCover(anime, onlyShowCover: true)),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 不要和动漫详细页里的复用，因为这里的不应该可以复制文字
                    _showAnimeName(anime.animeName),
                    // _showNameAnother(anime.nameAnother),
                    _showAnimeInfo(anime.getAnimeInfoFirstLine()),
                    _showAnimeInfo(anime.getAnimeInfoSecondLine()),
                    // _showCollectIcon(anime)
                  ],
                ),
              ),
              _showCollectIcon(anime)
            ],
          ),
        ),
      );
    }, childCount: directory.length));
  }

  _buildFilterBody() {
    return ListView(
      shrinkWrap: true, //解决无限高度问题
      physics: const NeverScrollableScrollPhysics(), //禁用滑动事件
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
          child: SizedBox(
            // 给出高度才可以横向排列
            height: 30,
            child: Row(
              children: [
                GestureDetector(
                  child: const Text("年份："),
                  onTap: () {
                    int defaultYear = filter.year.isEmpty
                        ? DateTime.now().year
                        : int.parse(filter.year);
                    dialogSelectUint(context, "选择年份",
                            minValue: 2000,
                            maxValue: DateTime.now().year + 2,
                            initialValue: defaultYear)
                        .then((value) {
                      if (value == null || value == 0 || value == defaultYear) {
                        Log.info("未选择，直接返回");
                        return;
                      }
                      Log.info("选择了$value");
                      filter.year = value.toString();
                      _refreshController.requestRefresh();
                    });
                  },
                ),
                // Row嵌套ListView，需要使用Expanded嵌套ListView
                Expanded(
                  child: ListView(
                    // 横向滚动
                    scrollDirection: Axis.horizontal,
                    children: _showRadioYear(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
          child: SizedBox(
            height: 30,
            child: Row(
              children: [
                const Text("季度："),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _showRadioSeason(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
          child: SizedBox(
            height: 30,
            child: Row(
              children: [
                const Text("地区："),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _showRadioRegion(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
          child: SizedBox(
            height: 30,
            child: Row(
              children: [
                const Text("状态："),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _showRadioStatus(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
          child: SizedBox(
            height: 30,
            child: Row(
              children: [
                const Text("类型："),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _showRadioCategory(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        )
      ],
    );
  }

  _buildFilter() {
    // 使用插件expand_widget
    // 缺点：不能设置默认为展开状态
    // return ExpandChild(
    //   child: _buildFilterBody(),
    //   expandArrowStyle: ExpandArrowStyle.both,
    //   expandedHint: "收起过滤",
    //   collapsedHint: "展开过滤",
    // );

    // 使用自带的折叠
    return ExpansionPanelList(
        elevation: 0,
        expandedHeaderPadding: EdgeInsets.zero,
        expansionCallback: (panelIndex, isExpanded) {
          setState(() {
            Global.expandDirectoryFilter = !Global.expandDirectoryFilter;
          });
        },
        animationDuration: kThemeAnimationDuration,
        children: <ExpansionPanel>[
          ExpansionPanel(
            backgroundColor: ThemeUtil.getAppBarBackgroundColor(),
            headerBuilder: (context, isExpanded) {
              return _buildSourceTile();
            },
            isExpanded: Global.expandDirectoryFilter,
            // canTapOnHeader: true,
            body: _buildFilterBody(),
          )
        ]);
  }

  _showRadioYear() {
    List<Widget> children = [];

    List<String> years = [""]; // 空字符串对应全部
    // groupValue(filter.year)对应选中的value
    int endYear = DateTime.now().year;
    for (int year = endYear; year >= 2000; --year) {
      years.add("$year"); // 转为字符串
    }

    for (var i = 0; i < years.length; i++) {
      children.add(Row(
        children: [
          Radio(
              value: years[i],
              groupValue: filter.year,
              onChanged: (value) {
                filter.year = value.toString();
                // Log.info(filter.year);
                _refreshController.requestRefresh();
              }),
          Text(i == 0 ? "全部" : (i == years.length - 1 ? "2000以前" : years[i]))
        ],
      ));
    }
    return children;
  }

  _showRadioSeason() {
    List<Widget> children = [];

    var seasons = ["", "1", "4", "7", "10"];
    for (var i = 0; i < seasons.length; i++) {
      children.add(Row(
        children: [
          Radio(
              value: seasons[i],
              groupValue: filter.season,
              onChanged: (value) {
                filter.season = value.toString();
                // Log.info(filter.season);
                _refreshController.requestRefresh();
              }),
          Text(i == 0 ? "全部" : "${seasons[i]} 月")
        ],
      ));
    }
    return children;
  }

  _showRadioRegion() {
    List<Widget> children = [];

    var regions = ["", "日本", "中国", "欧美"];
    for (var i = 0; i < regions.length; i++) {
      children.add(Row(
        children: [
          Radio(
              value: regions[i],
              groupValue: filter.region,
              onChanged: (value) {
                filter.region = value.toString();
                _refreshController.requestRefresh();
              }),
          Text(i == 0 ? "全部" : regions[i])
        ],
      ));
    }
    return children;
  }

  _showRadioStatus() {
    List<Widget> children = [];

    var statuss = ["", "连载", "完结", "未播放"];
    for (var i = 0; i < statuss.length; i++) {
      children.add(Row(
        children: [
          Radio(
              value: statuss[i],
              groupValue: filter.status,
              onChanged: (value) {
                filter.status = value.toString();
                _refreshController.requestRefresh();
              }),
          Text(i == 0 ? "全部" : statuss[i])
        ],
      ));
    }
    return children;
  }

  _showRadioCategory() {
    List<Widget> children = [];

    var categorys = ["", "TV", "剧场版", "OVA"];
    for (var i = 0; i < categorys.length; i++) {
      children.add(Row(
        children: [
          Radio(
              value: categorys[i],
              groupValue: filter.category,
              onChanged: (value) {
                filter.category = value.toString();
                _refreshController.requestRefresh();
              }),
          Text(i == 0 ? "全部" : categorys[i])
        ],
      ));
    }
    return children;
  }

  _showAnimeName(animeName) {
    return Container(
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.fromLTRB(0, 5, 15, 5),
      child: Text(
        animeName,
        style: TextStyle(
            fontWeight: FontWeight.w600, color: ThemeUtil.getFontColor()),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  _showNameAnother(String nameAnother) {
    return nameAnother.isEmpty
        ? Container()
        : Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.fromLTRB(0, 5, 15, 0),
            child: Text(
              nameAnother,
              style: TextStyle(color: ThemeUtil.getCommentColor(), height: 1.1),
              overflow: TextOverflow.ellipsis,
              textScaleFactor: ThemeUtil.smallScaleFactor,
            ),
          );
  }

  _showAnimeInfo(String animeInfo) {
    return animeInfo.isEmpty
        ? Container()
        : Container(
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.fromLTRB(0, 5, 15, 0),
            child: Text(
              animeInfo,
              style: TextStyle(color: ThemeUtil.getCommentColor(), height: 1.1),
              overflow: TextOverflow.ellipsis,
              textScaleFactor: ThemeUtil.smallScaleFactor,
            ),
          );
  }

  _showCollectIcon(Anime anime) {
    return SizedBox(
      height: _itemHeight,
      child: MaterialButton(
        padding: EdgeInsets.zero,
        visualDensity:
            const VisualDensity(horizontal: VisualDensity.minimumDensity),
        onPressed: () {
          dialogSelectChecklist(setState, context, anime);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            anime.isCollected()
                ? const Icon(Icons.favorite, color: Colors.red, size: 18)
                : const Icon(Icons.favorite_border, size: 18),
            anime.isCollected()
                ? Text(anime.tagName,
                    textScaleFactor: ThemeUtil.tinyScaleFactor)
                : Container()
          ],
        ),
      ),
    );
  }
}
