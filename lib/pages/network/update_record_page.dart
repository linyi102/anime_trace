import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/params/page_params.dart';
import 'package:flutter_test_future/classes/vo/update_record_vo.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/utils/dao/update_record_dao.dart';
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

  int pageIndex = 0;
  int pageSize = 5;
  final UpdateRecordController updateRecordController =
      Get.put(UpdateRecordController());

  _initData() async {
    // UpdateRecordDao.findAll(PageParams(pageIndex, pageSize));
    // if (updateRecordController.updateRecordVos.isEmpty) { // 如果表中数据为空，则每次进入该页面都会请求，所以使用initOk
    if (!updateRecordController.initOk) {
      updateRecordController.updateData();
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
        child: ListView.builder(
          itemCount: updateRecordController.updateRecordVos.length,
          itemBuilder: (context, index) {
            // debugPrint("index=$index");
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
    );
  }
}
