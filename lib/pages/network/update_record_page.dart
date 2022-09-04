import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/params/page_params.dart';
import 'package:flutter_test_future/classes/vo/update_record_vo.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/time_show_util.dart';
import 'package:get/get.dart';

import '../../components/dialog/dialog_update_all_anime_progress.dart';

class UpdateRecordPage extends StatelessWidget {
  UpdateRecordPage({Key? key}) : super(key: key);

  final UpdateRecordController updateRecordController = Get.find();

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => RefreshIndicator(
        onRefresh: () async {
          ClimbAnimeUtil.updateAllAnimesInfo().then((value) {
            if (value) {
              dialogUpdateAllAnimeProgress(context);
            }
          });
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: updateRecordController.updateRecordVos.isEmpty
              ? ListView(
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
                )
              : Scrollbar(
                  controller: _scrollController,
                  child: ListView.builder(
                    // 解决item太小无法下拉
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollController,
                    itemCount: updateRecordController.updateRecordVos.length,
                    itemBuilder: (context, index) {
                      // debugPrint("index=$index");
                      // 下拉到还剩两天的时候请求更多
                      PageParams pageParams = updateRecordController.pageParams;
                      // 即使全部加载了，也会一直加载
                      // if (index + 2 == updateRecordController.updateRecordVos.length) {
                      // 必须要pageIndex+1，这样当pageIndex为0时，右值为pageSize
                      // 该方法可以避免一直加载的原因：即使最后多请求一次，右值会变大，左值不会再与右值相等
                      if (index + 2 ==
                          (pageParams.pageIndex + 1) * pageParams.pageSize) {
                        updateRecordController.loadMore();
                      }
                      UpdateRecordVo updateRecordVo =
                          updateRecordController.updateRecordVos[index];
                      String curDate = updateRecordVo.manualUpdateTime;
                      ListTile animeRow = ListTile(
                        leading: AnimeListCover(updateRecordVo.anime),
                        trailing: Text(
                            "${updateRecordVo.oldEpisodeCnt} >> ${updateRecordVo.newEpisodeCnt}",
                            textScaleFactor: 0.9),
                        // trailing: Text(
                        //     "${updateRecordVo.oldEpisodeCnt} > ${updateRecordVo.newEpisodeCnt}",
                        //     textScaleFactor: 0.9),
                        title: Text(
                          updateRecordVo.anime.animeName,
                          textScaleFactor: 0.9,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // subtitle: Text(updateRecordVo.anime.getAnimeSource()),
                        onTap: () {
                          Navigator.of(context).push(FadeRoute(
                            builder: (context) {
                              return AnimeDetailPlus(
                                  updateRecordVo.anime.animeId);
                            },
                          ));
                        },
                      );
                      // 不能通过该动漫的更新日期和preDate(上一个日期)比较来判断是否进入下一个日期。从下往上移动的时候就会出错
                      // if (preDate != curDate) {
                      //   preDate = curDate;
                      // 可以通过相邻两个index比较：该动漫永远和上一个相邻动漫比较，如果日期不一样，就在该动漫上面添加日期即可
                      if (index == 0 ||
                          updateRecordController.updateRecordVos[index - 1]
                                  .manualUpdateTime !=
                              updateRecordVo.manualUpdateTime) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(18, 15, 0, 15),
                              child: Text(TimeShowUtil.getShowDateStr(curDate)),
                            ),
                            animeRow
                          ],
                        );
                      }
                      return animeRow;
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
