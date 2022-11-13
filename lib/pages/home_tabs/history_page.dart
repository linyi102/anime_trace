import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/components/fade_animated_switcher.dart';
import 'package:flutter_test_future/dao/history_dao.dart';
import 'package:flutter_test_future/models/history_plus.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:toggle_switch/toggle_switch.dart';

class HistoryView {
  String label;
  PageParams pageParams;
  int dateLength; // 用于匹配数据库中日期xxxx-xx-xx的子串
  List<HistoryPlus> historyRecords = [];
  ScrollController scrollController = ScrollController();
  // Future<List<DateHistoryRecord>> Function(PageParams) loadData;

  HistoryView(
      {required this.label,
      required this.pageParams,
      required this.dateLength});
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HistoryView> views = [
    HistoryView(
        label: "年",
        pageParams: PageParams(pageIndex: 0, pageSize: 5),
        dateLength: 4),
    HistoryView(
        label: "月",
        pageParams: PageParams(pageIndex: 0, pageSize: 10),
        dateLength: 7),
    HistoryView(
        label: "日",
        pageParams: PageParams(pageIndex: 0, pageSize: 30),
        dateLength: 10)
  ];
  int selectedViewIndex =
      SPUtil.getInt("selectedViewIndexInHistoryPage", defaultValue: 1);
  bool loadOk = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  _initData({bool forceLoad = false}) async {
    if (forceLoad) {
      // 如果强制初始化数据，则需要恢复为初始状态
      for (var view in views) {
        view.pageParams.pageIndex = view.pageParams.baseIndex;
        view.historyRecords.clear();
      }
    }

    // 如果之前切换过该视图，使得不为空，就直接返回
    if (views[selectedViewIndex].historyRecords.isNotEmpty) {
      setState(() {});
      return;
    }

    views[selectedViewIndex].historyRecords =
        await HistoryDao.getHistoryPageable(
            pageParams: views[selectedViewIndex].pageParams,
            dateLength: views[selectedViewIndex].dateLength);
    loadOk = true;
    setState(() {
      Log.info("setState");
    });
  }

  _loadMoreData() async {
    Log.info("加载更多数据");
    views[selectedViewIndex].historyRecords.addAll(
        await HistoryDao.getHistoryPageable(
            pageParams: views[selectedViewIndex].pageParams,
            dateLength: views[selectedViewIndex].dateLength));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              const Text("历史", style: TextStyle(fontWeight: FontWeight.w600))),
      body: RefreshIndicator(
        onRefresh: () async => _initData(),
        child: FadeAnimatedSwitcher(
          loadOk: loadOk,
          destWidget: Column(
            children: [
              _buildViewSwitch(),
              views[selectedViewIndex].historyRecords.isEmpty
                  ? Expanded(child: emptyDataHint("什么都没有"))
                  : Expanded(
                      // 不能嵌套PageView，因为这样无法保证点击上面的视图实现切换，而是左右滑动切换
                      child: _buildHistoryPage(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Container _buildViewSwitch() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      child: ToggleSwitch(
        initialLabelIndex: selectedViewIndex,
        labels: views.map((e) => e.label).toList(),
        onToggle: (index) {
          // 重复点击当前tab，直接返回
          if (selectedViewIndex == index) return;

          selectedViewIndex = index ?? 0;
          Log.info(
              "切换index=$selectedViewIndex，label=${views[selectedViewIndex].label}");
          SPUtil.setInt("selectedViewIndexInHistoryPage", selectedViewIndex);
          _initData();
        },
        dividerColor: ThemeUtil.getCommentColor().withOpacity(0.2),
        minWidth: 50,
        // 方案1
        activeBgColor: [ThemeUtil.getPrimaryColor()],
        inactiveBgColor: ThemeUtil.getCardColor(),
        // 方案2
        // activeBgColor: const [Colors.transparent],
        // inactiveBgColor: ThemeUtil.getCardColor(),
        // activeFgColor: ThemeUtil.getPrimaryColor(),
      ),
    );
  }

  Scrollbar _buildHistoryPage() {
    return Scrollbar(
      controller: views[selectedViewIndex].scrollController,
      child: ListView.builder(
        // key保证切换视图时滚动条在最上面
        key: Key("$selectedViewIndex"),
        // TODO 为什么切换视图后滚动条不能恢复之前的位置？
        controller: views[selectedViewIndex].scrollController,
        itemCount: views[selectedViewIndex].historyRecords.length,
        itemBuilder: (context, index) {
          int threshold = views[selectedViewIndex].pageParams.getQueriedSize();
          Log.info("index=$index, threshold=$threshold");
          if (index + 2 == threshold) {
            views[selectedViewIndex].pageParams.pageIndex++;
            _loadMoreData();
          }

          String date = views[selectedViewIndex].historyRecords[index].date;

          return Card(
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                  // leading: Icon(
                  //   // Icons.timeline,
                  //   Icons.access_time,
                  //   color: ThemeUtil.getPrimaryColor(),
                  // ),
                  minLeadingWidth: 0,
                  title: Text(_formatDate(date),
                      textScaleFactor: ThemeUtil.smallScaleFactor),
                ),
                Column(
                    children: _buildViewRecords(context,
                        views[selectedViewIndex].historyRecords[index])),
                // 避免最后一项太靠近卡片底部，因为标题没有紧靠顶部，所以会导致不美观
                const SizedBox(height: 5)
              ],
            ),
          );
        },
      ),
    );
  }

  _formatDate(String date) {
    return date.replaceAll("-", "/");
  }

  _buildViewRecords(context, HistoryPlus historyRecord) {
    List<Widget> recordsWidget = [];

    for (var record in historyRecord.records) {
      recordsWidget.add(ListTile(
        leading: AnimeListCover(
          record.anime,
          reviewNumber: record.reviewNumber,
          showReviewNumber: true,
        ),
        subtitle: Text(
            (record.startEpisodeNumber == record.endEpisodeNumber
                ? record.startEpisodeNumber.toString()
                : "${record.startEpisodeNumber}~${record.endEpisodeNumber}"),
            textScaleFactor: ThemeUtil.tinyScaleFactor),
        title: Text(
          record.anime.animeName,
          // textScaleFactor: ThemeUtil.smallScaleFactor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // subtitle: Text(updateRecordVo.anime.getAnimeSource()),
        onTap: () {
          Navigator.of(context).push(FadeRoute(
            builder: (context) {
              return AnimeDetailPlus(record.anime);
            },
          )).then((value) => _initData(forceLoad: true));
        },
      ));
    }
    return recordsWidget;
  }
}
