import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/params/page_params.dart';
import 'package:flutter_test_future/classes/vo/update_record_vo.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:get/get.dart';

import '../../components/dialog/dialog_update_all_anime_progress.dart';

class UpdateRecordPage extends StatefulWidget {
  const UpdateRecordPage({Key? key}) : super(key: key);

  @override
  State<UpdateRecordPage> createState() => _UpdateRecordPageState();
}

class _UpdateRecordPageState extends State<UpdateRecordPage> {
  @override
  void initState() {
    super.initState();
    _initData();
  }

  final UpdateRecordController updateRecordController =
      Get.put(UpdateRecordController());

  _initData() {
    // if (updateRecordController.updateRecordVos.isEmpty) {
    // 如果表中数据为空，则每次进入该页面都会请求，所以使用initOk
    if (!updateRecordController.initOk) {
      // doubt：不用then时，第一次打开该页面时不会显示数据
      updateRecordController.updateData().then((value) {
        // setState(() {});
      });
    }
  }

  _formatDate(String date) {
    return date.replaceAll("-", "/");
  }

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
              ? Center(
                child: ListView(
                    shrinkWrap: true,
                    children: [emptyDataHint("暂无更新记录", toastMsg: "下拉更新已收藏动漫的信息")],
                    key: UniqueKey(),
                  ),
              )
              : Scrollbar(
                  child: ListView.builder(
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
                            "${updateRecordVo.oldEpisodeCnt} → ${updateRecordVo.newEpisodeCnt}",
                            textScaleFactor: 0.9),
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
                            ListTile(
                              title: Text(_formatDate(curDate)),
                              style: ListTileStyle.drawer,
                            ),
                            // Container(
                            //   padding: const EdgeInsets.fromLTRB(18, 15, 0, 15),
                            //   child: Text(_formatDate(curDate)),
                            // ),
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
