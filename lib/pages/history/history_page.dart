import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/animation/fade_animated_switcher.dart';
import 'package:flutter_test_future/dao/history_dao.dart';
import 'package:flutter_test_future/models/anime_history_record.dart';
import 'package:flutter_test_future/models/history_plus.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';

enum HistoryLabel {
  year("年"),
  month("月"),
  day("日");

  final String title;
  const HistoryLabel(this.title);
}

class HistoryView {
  HistoryLabel label;
  PageParams pageParams;
  int dateLength; // 用于匹配数据库中日期xxxx-xx-xx的子串
  List<HistoryPlus> historyRecords = [];
  ScrollController scrollController = ScrollController();

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
        label: HistoryLabel.year,
        pageParams: PageParams(pageIndex: 0, pageSize: 5),
        dateLength: 4),
    HistoryView(
        label: HistoryLabel.month,
        pageParams: PageParams(pageIndex: 0, pageSize: 10),
        dateLength: 7),
    HistoryView(
        label: HistoryLabel.day,
        pageParams: PageParams(pageIndex: 0, pageSize: 15),
        dateLength: 10)
  ];
  int selectedViewIndex = SPUtil.getInt("selectedViewIndexInHistoryPage",
      defaultValue: 1); // 默认为1，也就是月视图
  bool loadOk = false;
  late HistoryLabel selectedHistoryLabel;

  @override
  void initState() {
    super.initState();

    selectedHistoryLabel = views[selectedViewIndex].label;
    _initData();
  }

  _initData({bool forceLoad = false}) async {
    if (forceLoad) {
      Log.info("强制刷新，清空记录");
      // 如果强制初始化数据，则需要恢复为初始状态
      for (var view in views) {
        view.pageParams.pageIndex = view.pageParams.baseIndex;
        view.historyRecords.clear();
      }
      setState(() {
        loadOk = false;
      });
    }

    // 如果之前切换过该视图，使得不为空，就直接返回
    if (views[selectedViewIndex].historyRecords.isNotEmpty) {
      setState(() {
        loadOk = true;
      });
      return;
    }

    views[selectedViewIndex].historyRecords =
        await HistoryDao.getHistoryPageable(
            pageParams: views[selectedViewIndex].pageParams,
            dateLength: views[selectedViewIndex].dateLength);
    setState(() {
      loadOk = true;
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
        title: const Text("历史", style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [_buildCupertinoViewSwitch()],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _initData(forceLoad: true),
        child: FadeAnimatedSwitcher(
          loadOk: loadOk,
          destWidget: Column(
            children: [
              // _buildViewSwitch(),
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

  _buildCupertinoViewSwitch() {
    return CupertinoSlidingSegmentedControl(
      groupValue: selectedHistoryLabel,
      children: () {
        Map<HistoryLabel, Widget> map = {};
        for (int i = 0; i < views.length; ++i) {
          var view = views[i];
          map[view.label] = Text(view.label.title);
        }
        return map;
      }(),
      onValueChanged: (HistoryLabel? value) {
        if (value != null) {
          Log.info("value=$value");
          setState(() {
            // 先重绘进度圈和开关
            loadOk = false;
            selectedHistoryLabel = value;
          });
          selectedViewIndex =
              views.indexWhere((element) => element.label == value);
          SPUtil.setInt("selectedViewIndexInHistoryPage", selectedViewIndex);
          _initData();
        }
      },
    );
  }

  Scrollbar _buildHistoryPage() {
    return Scrollbar(
      controller: views[selectedViewIndex].scrollController,
      child: ListView.builder(
        // key保证切换视图时滚动条在最上面
        key: Key("history-page-view-$selectedViewIndex"),
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
                // 卡片标题
                ListTile(
                  minLeadingWidth: 0,
                  title:
                      Text(date, textScaleFactor: ThemeUtil.smallScaleFactor),
                  trailing: Text(
                    "${views[selectedViewIndex].historyRecords[index].records.length}个动漫",
                    textScaleFactor: 0.8,
                    style: TextStyle(color: ThemeUtil.getCommentColor()),
                  ),
                ),
                // 卡片主体
                Column(
                    children: views[selectedViewIndex]
                        .historyRecords[index]
                        .records
                        .map((record) => RecordItem(record: record, date: date))
                        .toList()),
                // 避免最后一项太靠近卡片底部，因为标题没有紧靠顶部，所以会导致不美观
                const SizedBox(height: 5)
              ],
            ),
          );
        },
      ),
    );
  }
}

class RecordItem extends StatefulWidget {
  final AnimeHistoryRecord record;
  final String date;

  const RecordItem({required this.record, required this.date, Key? key})
      : super(key: key);

  @override
  State<RecordItem> createState() => _RecordItemState();
}

class _RecordItemState extends State<RecordItem> {
  late AnimeHistoryRecord record;

  @override
  void initState() {
    super.initState();
    record = widget.record;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) {
            return AnimeDetailPage(record.anime);
          },
        )).then((value) async {
          record = await HistoryDao.getRecordByAnimeIdAndReviewNumberAndDate(
              record.anime, record.reviewNumber, widget.date);
          setState(() {});
        });
      },
    );
  }
}
