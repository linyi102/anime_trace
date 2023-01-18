import 'package:flutter/material.dart';

import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/models/vo/update_record_vo.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/pages/network/need_update_anime_list.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/time_show_util.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../../utils/theme_util.dart';

class UpdateRecordPage extends StatelessWidget {
  UpdateRecordPage({Key? key}) : super(key: key);
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final UpdateRecordController updateRecordController = Get.find();

    return Obx(
      () => RefreshIndicator(
        onRefresh: () async {
          ClimbAnimeUtil.updateAllAnimesInfo();
        },
        // ListView嵌套ListView，那么内部LV会需要加上shrinkWrap: true，但这样会导致懒加载实现
        // 所以改用Column
        child: Column(
          children: [
            _buildUpdateProgress(context),
            Expanded(
                child: updateRecordController.updateRecordVos.isEmpty
                    ? _buildEmptyDataPage()
                    : _buildUpdateRecordList(updateRecordController)),
          ],
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
      child: ListView.builder(
          controller: scrollController,
          itemCount: dateList.length,
          itemBuilder: (context, index) {
            String date = dateList[index];
            PageParams pageParams = updateRecordController.pageParams;
            Log.info("$index, ${pageParams.getQueriedSize()}");
            if (index + 2 == pageParams.getQueriedSize()) {
              updateRecordController.loadMore();
            }

            return Card(
              elevation: 0,
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                        TimeShowUtil.getHumanReadableDateTimeStr(date,
                            showTime: false, showDayOfWeek: true),
                        textScaleFactor: ThemeUtil.smallScaleFactor),
                    trailing: Text(
                      "${map[date]!.length}个动漫",
                      textScaleFactor: 0.8,
                      style: TextStyle(color: ThemeUtil.getCommentColor()),
                    ),
                  ),
                  Column(children: _buildRecords(context, map[date]!)),
                  // 避免最后一项太靠近卡片底部，因为标题没有紧靠顶部，所以会导致不美观
                  const SizedBox(height: 5)
                ],
              ),
            );
          }),
    );
  }

  _buildRecords(context, List<UpdateRecordVo> records) {
    List<Widget> recordsWidget = [];
    for (var record in records) {
      recordsWidget.add(ListTile(
        leading: AnimeListCover(record.anime),
        subtitle: Text("更新至${record.newEpisodeCnt}集",
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
              return AnimeDetailPlus(record.anime);
            },
          ));
        },
      ));
    }
    return recordsWidget;
  }

  _buildEmptyDataPage() {
    return ListView(
      children: [emptyDataHint("尝试下拉更新动漫")],
    );
  }

  _buildUpdateProgress(context) {
    final UpdateRecordController updateRecordController = Get.find();
    int updateOkCnt = updateRecordController.updateOkCnt.value;
    int needUpdateCnt = updateRecordController.needUpdateCnt.value;

    return GestureDetector(
      onTap: () {
        Log.info("进入页面");
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return const NeedUpdateAnimeList();
        }));
      },
      child: Container(
        height: 60,
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: ThemeUtil.getCardColor()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Container()),
                Text("更新进度：$updateOkCnt/$needUpdateCnt",
                    textScaleFactor: ThemeUtil.smallScaleFactor),
                Text("查看未完结动漫",
                    textScaleFactor: ThemeUtil.tinyScaleFactor,
                    style: TextStyle(color: ThemeUtil.getCommentColor())),
                Expanded(child: Container()),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                ClimbAnimeUtil.updateAllAnimesInfo();
              },
              style: ButtonStyle(
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)))),
              child: const Text(
                "立即更新",
                textScaleFactor: ThemeUtil.smallScaleFactor,
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

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
