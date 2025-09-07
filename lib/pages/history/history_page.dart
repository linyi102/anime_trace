import 'package:animetrace/widgets/connected_button_groups.dart';
import 'package:flutter/material.dart';

import 'package:animetrace/components/anime_list_cover.dart';
import 'package:animetrace/components/empty_data_hint.dart';
import 'package:animetrace/animation/fade_animated_switcher.dart';
import 'package:animetrace/dao/history_dao.dart';
import 'package:animetrace/models/anime_history_record.dart';
import 'package:animetrace/pages/anime_detail/anime_detail.dart';
import 'package:animetrace/pages/history/history_controller.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/sp_util.dart';
import 'package:animetrace/utils/time_util.dart';
import 'package:animetrace/values/theme.dart';
import 'package:animetrace/widgets/common_divider.dart';
import 'package:animetrace/widgets/responsive.dart';
import 'package:animetrace/widgets/setting_title.dart';
import 'package:get/get.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  HistoryController historyController = Get.put(HistoryController());
  List<HistoryView> get views => historyController.views;

  @override
  void initState() {
    historyController.loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildMaterialViewSwitch(),
            Expanded(
              child: GetBuilder<HistoryController>(
                init: historyController,
                builder: (_) => PageView(
                  // 后期如果需要滑动切换视图可以放开
                  physics: const NeverScrollableScrollPhysics(),
                  controller: historyController.pageController,
                  children: historyController.views
                      .map((e) => _buildHistoryPage(e))
                      .toList(),
                  onPageChanged: (index) {
                    setState(() {
                      historyController.curViewIndex = index;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialViewSwitch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConnectedButtonGroups<int>(
            items: historyController.views
                .map((e) => ConnectedButtonItem(
                      // icon: Icon(e.label.iconData),
                      label: e.label.title,
                      value: e.label.index,
                    ))
                .toList(),
            selected: {historyController.selectedHistoryLabel.index},
            onSelectionChanged: (newSelection) {
              final to = newSelection.first;
              setState(() {
                historyController.curViewIndex = to;
              });
              historyController.pageController?.jumpToPage(to);
              SPUtil.setInt("selectedViewIndexInHistoryPage", to);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPage(HistoryView view) {
    return FadeAnimatedSwitcher(
      loadOk: historyController.loadOk,
      destWidget: view.historyRecords.isEmpty
          ? emptyDataHint(msg: "没有历史。")
          : RefreshIndicator(
              onRefresh: () async => await historyController.loadData(),
              child: _RecordListView(
                view: view,
                loadMoreData: historyController.loadMoreData,
              ),
            ),
    );
  }
}

class _RecordListView extends StatefulWidget {
  const _RecordListView({required this.view, required this.loadMoreData});
  final HistoryView view;
  final VoidCallback loadMoreData;

  @override
  State<_RecordListView> createState() => __RecordListViewState();
}

class __RecordListViewState extends State<_RecordListView>
    with AutomaticKeepAliveClientMixin {
  HistoryView get view => widget.view;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scrollbar(
      controller: view.scrollController,
      child: SuperListView.separated(
        separatorBuilder: (context, index) => const CommonDivider(thinkness: 0),
        // 保留滚动位置，注意：如果滚动位置在加载更多的数据中，那么重新打开当前页面若重新加载数据，则恢复滚动位置不合适，故不采用
        // key: PageStorageKey("history-page-view-$selectedViewIndex"),
        // 指定key后，才能保证切换回历史页时，update()后显示最新数据
        // key: UniqueKey(),
        // 但不能指定为UniqueKey，否则加载更多时会直接跳转到顶部。可是指定这个下面key又会导致没有显示最新数据，并且新增历史后不匹配
        // 推测是RecordItem的key问题，后来为RecordItem添加UniqueKey后正确。
        // key: Key("history-page-view-$selectedViewIndex"),
        controller: view.scrollController,
        itemCount: view.historyRecords.length,
        itemBuilder: (context, cardIndex) {
          int threshold = view.pageParams.getQueriedSize();
          if (cardIndex + 2 == threshold) {
            AppLog.info("index=$cardIndex, threshold=$threshold");
            view.pageParams.pageIndex++;
            widget.loadMoreData();
          }

          String date = view.historyRecords[cardIndex].date;
          final records = view.historyRecords[cardIndex].records;

          return Card(
            child: Column(
              children: [
                // 卡片标题
                SettingTitle(
                  title: TimeUtil.isUnRecordedDateTimeStr(date)
                      ? '其他'
                      : date.replaceAll("-", "/"),
                  // trailing: Text(
                  //   "${view.historyRecords[cardIndex].records.length}个动漫",
                  //   style: Theme.of(context).textTheme.bodySmall,
                  // ),
                ),
                // 卡片主体
                Responsive(
                  mobile: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: records.length,
                    itemBuilder: (context, recordIndex) {
                      final record = records[recordIndex];
                      return _RecordItem(
                          record: record, date: date, useCard: false);
                    },
                  ),
                  desktop: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                            mainAxisExtent: 80, maxCrossAxisExtent: 320),
                    itemCount: records.length,
                    itemBuilder: (context, recordIndex) {
                      final record = records[recordIndex];
                      return _RecordItem(
                          record: record, date: date, useCard: true);
                    },
                  ),
                ),
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

class _RecordItem extends StatefulWidget {
  final AnimeHistoryRecord record;
  final String date;
  final bool useCard;

  const _RecordItem(
      {required this.record, required this.date, this.useCard = true});

  @override
  State<_RecordItem> createState() => _RecordItemState();
}

class _RecordItemState extends State<_RecordItem> {
  AnimeHistoryRecord get record => widget.record;

  @override
  Widget build(BuildContext context) {
    if (widget.useCard) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: _buildItem(context),
        ),
      );
    }
    return _buildItem(context);
  }

  InkWell _buildItem(BuildContext context) {
    return InkWell(
      borderRadius:
          widget.useCard ? BorderRadius.circular(AppTheme.cardRadius) : null,
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) {
            return AnimeDetailPage(record.anime);
          },
        )).then((value) async {
          final newRecord =
              await HistoryDao.getRecordByAnimeIdAndReviewNumberAndDate(
                  record.anime, record.reviewNumber, widget.date);
          record.assign(newRecord);
          setState(() {});
        });
      },
      child: ListTile(
        leading: AnimeListCover(
          record.anime,
          reviewNumber: record.reviewNumber,
          showReviewNumber: true,
        ),
        subtitle: Text(
          (record.startEpisodeNumber == record.endEpisodeNumber
              ? record.startEpisodeNumber.toString()
              : "${record.startEpisodeNumber}~${record.endEpisodeNumber}"),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        title: Text(
          record.anime.animeName,
          // textScaleFactor: AppTheme.smallScaleFactor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // subtitle: Text(updateRecordVo.anime.getAnimeSource()),
      ),
    );
  }
}
