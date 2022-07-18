import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/params/page_params.dart';
import 'package:flutter_test_future/classes/vo/update_record_vo.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:get/get.dart';

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
        setState(() {});
      });
    }
  }

  _refreshData() async {
    updateRecordController.updateData();
  }

  _formatDate(String date) {
    return date.replaceAll("-", "/");
  }

  @override
  Widget build(BuildContext context) {
    String preDate = "";
    return Obx(
      () => RefreshIndicator(
        onRefresh: () async {
          _refreshData();
        },
        child: updateRecordController.updateRecordVos.isEmpty
            ? emptyDataHint("暂无更新记录")
            : Scrollbar(
                child: ListView.builder(
                  itemCount: updateRecordController.updateRecordVos.length,
                  itemBuilder: (context, index) {
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
                        "${updateRecordVo.oldEpisodeCnt} > ${updateRecordVo.newEpisodeCnt}",
                        textScaleFactor: 0.9,
                      ),
                      title: Text(updateRecordVo.anime.animeName),
                      onTap: () {
                        Navigator.of(context).push(FadeRoute(
                          builder: (context) {
                            return AnimeDetailPlus(
                                updateRecordVo.anime.animeId);
                          },
                        ));
                      },
                    );
                    if (preDate != curDate) {
                      preDate = curDate;
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
    );
  }
}
