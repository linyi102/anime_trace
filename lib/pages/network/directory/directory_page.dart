import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_item_auto_load.dart';
import 'package:flutter_test_future/components/classic_refresh_style.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/components/website_logo.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/models/climb_website.dart';

import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/climb_quqi.dart';
import 'package:flutter_test_future/utils/climb/climb_yhdm.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/values/values.dart';
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

  final List<Climb> usableClimbs = [ClimbYhdm(), ClimbQuqi()];

  late final RefreshController _refreshController;

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
      // 如果已有数据，则直接显示
    }
  }

  @override
  void dispose() {
    super.dispose();
    //为了避免内存泄露，需要调用.dispose
    _scrollController.dispose();
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

  _buildAnimeSliverList() {
    if (directory.isEmpty) {
      return SliverToBoxAdapter(child: emptyDataHint());
    }

    return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
      Anime anime = directory[index];
      return AnimeItemAutoLoad(
        // 需要指定key，否则看不出来变化
        key: UniqueKey(),
        anime: anime,
        onChanged: (newAnime) => anime = newAnime,
        style: AnimeItemStyle.list,
        // 不会实时变化
        // subtitles: [
        //   anime.getAnimeInfoFirstLine(),
        //   anime.getAnimeInfoSecondLine()
        // ],
        showAnimeInfo: true,
        showProgress: true,
        showReviewNumber: true,
      );
    }, childCount: directory.length));
  }

  _buildFilterBody() {
    return ListView(
      shrinkWrap: true, //解决无限高度问题
      physics: const NeverScrollableScrollPhysics(), //禁用滑动事件
      children: [
        _buildFilterItemRow(
            name: "年份",
            children: _generateRadioYear(),
            onTapName: () => _showDialogSelectYear()),
        _buildFilterItemRow(name: "季度", children: _generateRadioSeason()),
        _buildFilterItemRow(name: "地区", children: _generateRadioRegion()),
        _buildFilterItemRow(name: "状态", children: _generateRadioStatus()),
        _buildFilterItemRow(name: "类型", children: _generateRadioCategory()),
        const SizedBox(height: 10),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.end,
        //   children: [
        //     TextButton(onPressed: () {}, child: const Text("重置")),
        //     const SizedBox(width: 10),
        //     ElevatedButton(
        //         onPressed: () {},
        //         child: const Text("查询", style: TextStyle(color: Colors.white)))
        //   ],
        // )
      ],
    );
  }

  void _showDialogSelectYear() {
    int defaultYear =
        filter.year.isEmpty ? DateTime.now().year : int.parse(filter.year);
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
  }

  _buildFilterItemRow({
    required String name,
    List<Widget> children = const [],
    void Function()? onTapName,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
      child: SizedBox(
        // 给出高度才可以横向排列
        height: 30,
        child: Row(
          children: [
            InkWell(onTap: onTapName, child: Text("$name：")),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: children,
              ),
            ),
          ],
        ),
      ),
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
    return Card(
      child: ExpansionPanelList(
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
          ]),
    );
  }

  _generateRadioYear() {
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

  _generateRadioSeason() {
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

  _generateRadioRegion() {
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

  _generateRadioStatus() {
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

  _generateRadioCategory() {
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
}
