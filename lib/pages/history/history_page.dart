import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/animation/fade_animated_switcher.dart';
import 'package:flutter_test_future/dao/history_dao.dart';
import 'package:flutter_test_future/models/anime_history_record.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/pages/history/history_controller.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:get/get.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  HistoryController historyController = Get.put(HistoryController());

  List<HistoryView> get views => historyController.views;
  int get selectedViewIndex => historyController.selectedViewIndex;

  @override
  void initState() {
    if (historyController.initOk) {
      // 如果已经初始化完毕，则说明之前已经打开过历史页，那么这次需要刷新数据来保证最新数据
      historyController.refreshData();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("历史", style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [_buildCupertinoViewSwitch()],
      ),
      body: RefreshIndicator(
        onRefresh: () async => await historyController.refreshData(),
        child: GetBuilder(
          init: historyController,
          builder: (_) => FadeAnimatedSwitcher(
            loadOk: historyController.loadOk,
            destWidget: Column(
              children: [
                // _buildViewSwitch(),
                views[selectedViewIndex].historyRecords.isEmpty
                    ? Expanded(child: emptyDataHint(msg: "没有历史。"))
                    : Expanded(
                        // 不能嵌套PageView，因为这样无法保证点击上面的视图实现切换，而是左右滑动切换
                        child: _buildHistoryPage(),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildCupertinoViewSwitch() {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: CupertinoSlidingSegmentedControl(
        groupValue: historyController.selectedHistoryLabel,
        children: () {
          Map<HistoryLabel, Widget> map = {};
          for (int i = 0; i < historyController.views.length; ++i) {
            var view = historyController.views[i];
            map[view.label] = Text(view.label.title);
          }
          return map;
        }(),
        onValueChanged: (HistoryLabel? value) {
          if (value != null) {
            Log.info("value=$value");
            setState(() {
              // 先重绘进度圈和开关
              historyController.loadOk = false;
              historyController.selectedHistoryLabel = value;
            });
            historyController.selectedViewIndex =
                views.indexWhere((element) => element.label == value);
            SPUtil.setInt("selectedViewIndexInHistoryPage", selectedViewIndex);
            historyController.loadData();
          }
        },
      ),
    );
  }

  Scrollbar _buildHistoryPage() {
    return Scrollbar(
      controller: views[selectedViewIndex].scrollController,
      child: ListView.builder(
        // 保留滚动位置，注意：如果滚动位置在加载更多的数据中，那么重新打开当前页面若重新加载数据，则恢复滚动位置不合适，故不采用
        // key: PageStorageKey("history-page-view-$selectedViewIndex"),
        // 指定key后，才能保证切换回历史页时，update()后显示最新数据
        key: UniqueKey(),
        controller: views[selectedViewIndex].scrollController,
        itemCount: views[selectedViewIndex].historyRecords.length,
        itemBuilder: (context, index) {
          int threshold = views[selectedViewIndex].pageParams.getQueriedSize();
          if (index + 2 == threshold) {
            Log.info("index=$index, threshold=$threshold");
            views[selectedViewIndex].pageParams.pageIndex++;
            historyController.loadMoreData();
          }

          String date = views[selectedViewIndex].historyRecords[index].date;

          return Card(
            elevation: 0,
            child: Column(
              children: [
                // 卡片标题
                ListTile(
                  minLeadingWidth: 0,
                  title: Text(
                    date.replaceAll("-", "/"),
                    // textScaleFactor: ThemeUtil.smallScaleFactor,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
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
