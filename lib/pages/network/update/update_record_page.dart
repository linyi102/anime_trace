import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_animated_switcher.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/dao/update_record_dao.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/models/vo/update_record_vo.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/widgets/responsive.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/time_util.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:flutter_test_future/widgets/common_divider.dart';
import 'package:flutter_test_future/widgets/setting_title.dart';
import 'package:get/get.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

class UpdateRecordPage extends StatefulWidget {
  const UpdateRecordPage({Key? key}) : super(key: key);

  @override
  State<UpdateRecordPage> createState() => _UpdateRecordPageState();
}

class _UpdateRecordPageState extends State<UpdateRecordPage> {
  final scrollController = ScrollController();

  UpdateRecordController get updateRecordController => Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "更新进度",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                updateRecordController.updateProgressStr,
                style: Theme.of(context).textTheme.bodySmall,
              )
            ],
          ),
          actions: [
            IconButton(
              onPressed: updateRecordController.updating.value
                  ? null
                  : () => ClimbAnimeUtil.updateAllAnimesInfo(),
              icon: const Icon(Icons.refresh),
            )
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ClimbAnimeUtil.updateAllAnimesInfo();
          },
          child: FadeAnimatedSwitcher(
            loadOk: updateRecordController.loadOk.value,
            destWidget: updateRecordController.updateRecordVos.isEmpty
                ? _buildEmptyDataPage()
                : _buildUpdateRecordList(updateRecordController),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateRecordList(UpdateRecordController updateRecordController) {
    List<String> dateList = [];
    Map<String, List<UpdateRecordVo>> map = {};
    for (var updateRecordVo in updateRecordController.updateRecordVos) {
      String key = updateRecordVo.manualUpdateDate();

      if (!map.containsKey(key)) {
        map[key] = [];
        dateList.add(key);
      }
      map[key]!.add(updateRecordVo);
    }

    return Scrollbar(
      controller: scrollController,
      child: ListView.separated(
          separatorBuilder: (context, index) =>
              const CommonDivider(thinkness: 0),
          controller: scrollController,
          // 避免没有占满时无法下拉刷新
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: dateList.length,
          itemBuilder: (context, index) {
            String date = dateList[index];
            PageParams pageParams = updateRecordController.pageParams;
            // Log.info("$index, ${pageParams.getQueriedSize()}");
            if (index + 2 == pageParams.getQueriedSize()) {
              updateRecordController.loadMore();
            }

            return Card(
              child: Column(
                children: [
                  SettingTitle(
                      title: TimeUtil.getHumanReadableDateTimeStr(
                    date,
                    showTime: false,
                    showDayOfWeek: true,
                    chineseDelimiter: true,
                    removeLeadingZero: true,
                  )),
                  Responsive(
                    mobile: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children:
                          _buildRecords(context, map[date]!, useCard: false),
                    ),
                    desktop: GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                              mainAxisExtent: 80, maxCrossAxisExtent: 320),
                      children:
                          _buildRecords(context, map[date]!, useCard: true),
                    ),
                  ),
                  // 避免最后一项太靠近卡片底部，因为标题没有紧靠顶部，所以会导致不美观
                  const SizedBox(height: 5),
                ],
              ),
            );
          }),
    );
  }

  List<Widget> _buildRecords(
    context,
    List<UpdateRecordVo> records, {
    bool useCard = false,
  }) {
    List<Widget> recordsWidget = [];
    for (var i = 0; i < records.length; ++i) {
      var record = records[i];
      recordsWidget
          .add(_buildRecordItem(context, record, records, useCard: useCard));
    }
    return recordsWidget;
  }

  Widget _buildRecordItem(
    context,
    UpdateRecordVo record,
    List<UpdateRecordVo> records, {
    bool useCard = false,
  }) {
    _buildItem() {
      return InkWell(
        borderRadius:
            useCard ? BorderRadius.circular(AppTheme.cardRadius) : null,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) {
              return AnimeDetailPage(record.anime);
            },
          )).then((popAnime) {
            setState(() {
              record.anime = popAnime;
            });
          });
        },
        onLongPress: () {
          // 提供删除操作
          _showDialogAboutRecordItem(context, record, records);
        },
        child: ListTile(
          leading: AnimeListCover(record.anime),
          subtitle: Text(
            "更新至 ${record.newEpisodeCnt} 集",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          title: Text(
            record.anime.animeName,
            // textScaleFactor: AppTheme.smallScaleFactor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (useCard) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: _buildItem(),
        ),
      );
    }
    return _buildItem();
  }

  _showDialogAboutRecordItem(
      context, UpdateRecordVo record, List<UpdateRecordVo> records) async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          children: [
            ListTile(
              onTap: () async {
                // 删除数据库数据
                bool deleteOk = await UpdateRecordDao.delete(record.id);
                if (deleteOk) {
                  // 删除内存数据
                  // records.remove(record); // 错误
                  UpdateRecordController.to.updateRecordVos
                      .remove(record); // 应删除控制器中的数据
                  // 关闭对话框
                  Navigator.pop(dialogContext);
                  // 提示
                  ToastUtil.showText("删除成功");
                } else {
                  ToastUtil.showText("删除失败");
                }
              },
              title: const Text("删除记录"),
              leading: const Icon(Icons.delete),
            )
          ],
        );
      },
    );
  }

  Widget _buildEmptyDataPage() {
    return ListView(
      children: [
        const SizedBox(height: 20),
        emptyDataHint(msg: "没有更新记录。"),
      ],
    );
  }
}
