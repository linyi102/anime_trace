import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/models/vo/update_record_vo.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/time_show_util.dart';
import 'package:get/get.dart';

import '../../components/dialog/dialog_update_all_anime_progress.dart';
import '../../utils/theme_util.dart';

class UpdateRecordPage extends StatelessWidget {
  const UpdateRecordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UpdateRecordController updateRecordController = Get.find();

    return Obx(
      () => RefreshIndicator(
        onRefresh: () async {
          // 如果返回false，则不会弹出更新进度消息
          ClimbAnimeUtil.updateAllAnimesInfo().then((value) {
            if (value) {
              dialogUpdateAllAnimeProgress(context);
            }
          });
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: updateRecordController.updateRecordVos.isEmpty
              ? _buildEmptyDataPage(context)
              : Column(
                  children: [
                    // _buildUpdateProgressBar(),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: _buildUpdateRecordList(updateRecordController),
                    )),
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
      String key = updateRecordVo.manualUpdateTime;
      if (!map.containsKey(key)) {
        map[key] = [];
        dateList.add(key);
      }
      map[key]!.add(updateRecordVo);
    }

    return ListView.builder(
        controller: ScrollController(),
        // 解决item太小无法下拉
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: dateList.length,
        itemBuilder: (context, index) {
          String date = dateList[index];
          PageParams pageParams = updateRecordController.pageParams;
          if (index + 2 == (pageParams.pageIndex + 1) * pageParams.pageSize) {
            updateRecordController.loadMore();
          }

          return Card(
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                    title: Text(
                        TimeShowUtil.getHumanReadableDateTimeStr(date,
                            showTime: false),
                        textScaleFactor: ThemeUtil.smallScaleFactor)),
                Column(children: _buildRecords(context, map[date]!)),
                // 避免最后一项太靠近卡片底部，因为标题没有紧靠顶部，所以会导致不美观
                const SizedBox(height: 5)
              ],
            ),
          );
        });
  }

  _buildRecords(context, List<UpdateRecordVo> records) {
    List<Widget> recordsWidget = [];
    for (var record in records) {
      recordsWidget.add(ListTile(
        leading: AnimeListCover(record.anime),
        // trailing: Transform.scale(
        //   scale: 0.8,
        //   child: Chip(
        //       label: Text("${record.oldEpisodeCnt}>${record.newEpisodeCnt}",
        //           textScaleFactor: ThemeUtil.smallScaleFactor)),
        // ),
        subtitle: Text("更新至${record.newEpisodeCnt}集",
            textScaleFactor: ThemeUtil.tinyScaleFactor),
        title: Text(
          record.anime.animeName,
          textScaleFactor: ThemeUtil.smallScaleFactor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // subtitle: Text(updateRecordVo.anime.getAnimeSource()),
        onTap: () {
          Navigator.of(context).push(FadeRoute(
            builder: (context) {
              return AnimeDetailPlus(record.anime.animeId);
            },
          ));
        },
      ));
    }
    return recordsWidget;
  }

  _buildEmptyDataPage(BuildContext context) {
    return ListView(
      // 解决无法下拉刷新
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          // 不能用无限高度(因为是ListView可以滚动)，只能通过下面方式获取高度
          height: MediaQuery.of(context).size.height -
              MediaQueryData.fromWindow(window).padding.top -
              kToolbarHeight -
              kBottomNavigationBarHeight -
              kMinInteractiveDimension,
          // color: Colors.red,
          child: emptyDataHint("暂无更新记录", toastMsg: "下拉更新已收藏动漫的信息"),
        )
      ],
      key: UniqueKey(),
    );
  }
}
