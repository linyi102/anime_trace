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
import 'package:animetrace/widgets/common_scaffold_body.dart';
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
      body: CommonScaffoldBody(
        child: Column(
          children: [
            _buildMaterialViewSwitch(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => await historyController.refreshData(),
                child: GetBuilder<HistoryController>(
                  init: historyController,
                  builder: (_) => FadeAnimatedSwitcher(
                    loadOk: historyController.loadOk,
                    destWidget: views[selectedViewIndex].historyRecords.isEmpty
                        ? emptyDataHint(msg: "没有历史。")
                        : _buildHistoryPage(),
                  ),
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConnectedButtonGroups(
            items: historyController.views
                .map((e) => ConnectedButtonItem(
                      // icon: Icon(e.label.iconData),
                      label: e.label.title,
                      value: e.label,
                    ))
                .toList(),
            selected: {historyController.selectedHistoryLabel},
            onSelectionChanged: (newSelection) {
              setState(() {
                // 先重绘进度圈和开关
                historyController.loadOk = false;
                historyController.selectedHistoryLabel = newSelection.first;
              });
              historyController.selectedViewIndex = views
                  .indexWhere((element) => element.label == newSelection.first);
              SPUtil.setInt(
                  "selectedViewIndexInHistoryPage", selectedViewIndex);
              // 重置页号刷新数据，避免页号不是从0开始导致加载直接加载后面的数据
              historyController.refreshData();
            },
          ),
        ],
      ),
    );
  }

  Scrollbar _buildHistoryPage() {
    return Scrollbar(
      controller: views[selectedViewIndex].scrollController,
      child: SuperListView.separated(
        separatorBuilder: (context, index) => const CommonDivider(thinkness: 0),
        // 保留滚动位置，注意：如果滚动位置在加载更多的数据中，那么重新打开当前页面若重新加载数据，则恢复滚动位置不合适，故不采用
        // key: PageStorageKey("history-page-view-$selectedViewIndex"),
        // 指定key后，才能保证切换回历史页时，update()后显示最新数据
        // key: UniqueKey(),
        // 但不能指定为UniqueKey，否则加载更多时会直接跳转到顶部。可是指定这个下面key又会导致没有显示最新数据，并且新增历史后不匹配
        // 推测是RecordItem的key问题，后来为RecordItem添加UniqueKey后正确。
        // key: Key("history-page-view-$selectedViewIndex"),
        controller: views[selectedViewIndex].scrollController,
        itemCount: views[selectedViewIndex].historyRecords.length,
        itemBuilder: (context, cardIndex) {
          int threshold = views[selectedViewIndex].pageParams.getQueriedSize();
          if (cardIndex + 2 == threshold) {
            Log.info("index=$cardIndex, threshold=$threshold");
            views[selectedViewIndex].pageParams.pageIndex++;
            historyController.loadMoreData();
          }

          String date = views[selectedViewIndex].historyRecords[cardIndex].date;
          final records =
              views[selectedViewIndex].historyRecords[cardIndex].records;

          return Card(
            child: Column(
              children: [
                // 卡片标题
                SettingTitle(
                  title: TimeUtil.isUnRecordedDateTimeStr(date)
                      ? '其他'
                      : date.replaceAll("-", "/"),
                  // trailing: Text(
                  //   "${views[selectedViewIndex].historyRecords[index].records.length}个动漫",
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
                      return _buildRecordItem(record, date, useCard: false);
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
                      return _buildRecordItem(record, date, useCard: true);
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

  _RecordItem _buildRecordItem(
    AnimeHistoryRecord record,
    String date, {
    bool useCard = false,
  }) {
    return _RecordItem(
      record: record,
      date: date,
      key: ObjectKey(record),
      useCard: useCard,
    );
  }
}

class _RecordItem extends StatefulWidget {
  final AnimeHistoryRecord record;
  final String date;
  final bool useCard;

  const _RecordItem(
      {required this.record,
      required this.date,
      this.useCard = true,
      super.key});

  @override
  State<_RecordItem> createState() => _RecordItemState();
}

class _RecordItemState extends State<_RecordItem> {
  late AnimeHistoryRecord record = widget.record;

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
