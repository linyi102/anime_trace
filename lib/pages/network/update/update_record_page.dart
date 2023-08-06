import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_animated_switcher.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/anime_list_tile.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/dao/update_record_dao.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/models/vo/update_record_vo.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/pages/network/update/need_update_anime_list.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/time_util.dart';
import 'package:flutter_test_future/widgets/common_divider.dart';
import 'package:flutter_test_future/widgets/setting_title.dart';
import 'package:get/get.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

import '../../../components/anime_item_auto_load.dart';

class UpdateRecordPage extends StatelessWidget {
  UpdateRecordPage({Key? key}) : super(key: key);
  final scrollController = ScrollController();
  UpdateRecordController get updateRecordController => Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      body: Obx(
        () => RefreshIndicator(
          onRefresh: () async {
            ClimbAnimeUtil.updateAllAnimesInfo();
          },
          // ListView嵌套ListView，那么内部LV会需要加上shrinkWrap: true，但这样会导致懒加载实现
          // 所以改用Column
          child: Column(
            children: [
              _buildUpdateProgress(context),
              const CommonDivider(),
              Expanded(
                  child: FadeAnimatedSwitcher(
                      loadOk: updateRecordController.loadOk.value,
                      destWidget: updateRecordController.updateRecordVos.isEmpty
                          ? _buildEmptyDataPage()
                          : _buildUpdateRecordList(updateRecordController))),
            ],
          ),
        ),
      ),
    );
  }

  _buildUpdateRecordList(UpdateRecordController updateRecordController) {
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
          separatorBuilder: (context, index) => const CommonDivider(),
          controller: scrollController,
          // 避免没有占满时无法下拉刷新
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: dateList.length,
          itemBuilder: (context, index) {
            String date = dateList[index];
            PageParams pageParams = updateRecordController.pageParams;
            Log.info("$index, ${pageParams.getQueriedSize()}");
            if (index + 2 == pageParams.getQueriedSize()) {
              updateRecordController.loadMore();
            }

            return Column(
              children: [
                SettingTitle(
                    title: TimeUtil.getHumanReadableDateTimeStr(
                  date,
                  showTime: false,
                  showDayOfWeek: true,
                  chineseDelimiter: true,
                  removeLeadingZero: true,
                )),
                Column(children: _buildRecords(context, map[date]!)),
                // 避免最后一项太靠近卡片底部，因为标题没有紧靠顶部，所以会导致不美观
                const SizedBox(height: 5),
              ],
            );
          }),
    );
  }

  _buildRecords(context, List<UpdateRecordVo> records) {
    List<Widget> recordsWidget = [];
    for (var i = 0; i < records.length; ++i) {
      var record = records[i];
      recordsWidget.add(AnimeItemAutoLoad(
        anime: record.anime,
        style: AnimeItemStyle.list,
        subtitles: [
          "更新至${record.newEpisodeCnt}集",
        ],
        onChanged: (newAnime) {
          records[i].anime = newAnime;
          updateRecordController.update();
        },
        onLongPress: () {
          _showDialogAboutRecordItem(context, record, records);
        },
      ));
      // recordsWidget.add(ListTile(
      //   leading: AnimeListCover(record.anime),
      //   subtitle: Text(
      //     "更新至${record.newEpisodeCnt}集",
      //     style: Theme.of(context).textTheme.bodySmall,
      //   ),
      //   title: Text(
      //     record.anime.animeName,
      //     // textScaleFactor: AppTheme.smallScaleFactor,
      //     maxLines: 1,
      //     overflow: TextOverflow.ellipsis,
      //   ),
      //   // subtitle: Text(updateRecordVo.anime.getAnimeSource()),
      //   onTap: () {
      //     Navigator.of(context).push(MaterialPageRoute(
      //       builder: (context) {
      //         return AnimeDetailPage(record.anime);
      //       },
      //     ));
      //   },
      //   onLongPress: () {
      //     // 提供删除操作
      //     _showDialogAboutRecordItem(context, record, records);
      //   },
      // ));
    }
    return recordsWidget;
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

  _buildEmptyDataPage() {
    return ListView(
      children: [
        const SizedBox(height: 20),
        emptyDataHint(msg: "没有更新记录。"),
      ],
    );
  }

  _buildUpdateProgress(context) {
    final UpdateRecordController updateRecordController = Get.find();
    int updateOkCnt = updateRecordController.updateOkCnt.value;
    int needUpdateCnt = updateRecordController.needUpdateCnt.value;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return const NeedUpdateAnimeList();
                }));
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Container()),
                    Text(
                      "更新进度 $updateOkCnt/$needUpdateCnt",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    // Text("查看未完结", style: Theme.of(context).textTheme.bodySmall),
                    Expanded(child: Container()),
                  ],
                ),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: updateRecordController.updating.value
                ? null
                : () => ClimbAnimeUtil.updateAllAnimesInfo(),
            child: const Text(
              "更新",
              style: TextStyle(letterSpacing: 5),
            ),
            // label: const Text("更新"),
            // icon: const Icon(MingCuteIcons.mgc_refresh_2_line, size: 16),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  double _getUpdatePercent(int updateOkCnt, int needUpdateCnt) {
    if (needUpdateCnt == 0) {
      return 0;
    } else if (updateOkCnt > needUpdateCnt) {
      Log.info("error: updateOkCnt=$updateOkCnt, needUpdateCnt=$needUpdateCnt");
      return 1;
    } else {
      return updateOkCnt / needUpdateCnt;
    }
  }
}
