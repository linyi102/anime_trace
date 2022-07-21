import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/params/page_params.dart';
import 'package:flutter_test_future/classes/update_record.dart';
import 'package:flutter_test_future/classes/vo/update_record_vo.dart';
import 'package:flutter_test_future/utils/dao/update_record_dao.dart';
import 'package:get/get.dart';

class UpdateRecordController extends GetxController {
  PageParams pageParams = PageParams(0, 10); // 动漫列表页刷新时也要传入该变量
  RxInt updateOkCnt = 0.obs, needUpdateCnt = 0.obs;
  bool enableBatchInsertUpdateRecord = true; // 一条条插入效率太慢，且有bug，所以开启批量插入

  RxList<UpdateRecordVo> updateRecordVos = RxList.empty();

  @override
  void onInit() {
    super.onInit();
    debugPrint("UpdateRecordController: init");
    updateData();
  }

  // 更新记录页全局更新
  Future<void> updateData() async {
    debugPrint("重新获取数据库内容并覆盖");
    pageParams.pageIndex = 0; // 应该重置为0
    updateRecordVos.value = await UpdateRecordDao.findAll(pageParams);
  }

  // 加载更多，追加而非直接赋值
  loadMore() async {
    debugPrint("加载更多更新记录中...");
    pageParams.pageIndex++;
    updateRecordVos.value =
        updateRecordVos.toList() + await UpdateRecordDao.findAll(pageParams);
  }

  // 动漫详细页更新
  updateSingaleAnimeData(Anime oldAnime, Anime newAnime) {
    if (newAnime.animeEpisodeCnt <= oldAnime.animeEpisodeCnt) return;

    UpdateRecord updateRecord = UpdateRecord(
        animeId: newAnime.animeId,
        oldEpisodeCnt: oldAnime.animeEpisodeCnt,
        newEpisodeCnt: newAnime.animeEpisodeCnt,
        manualUpdateTime: DateTime.now().toString().substring(0, 10));
    UpdateRecordDao.batchInsert([updateRecord]);

    // 要么重新获取所有数据，要么直接转Vo添加
    UpdateRecordVo updateRecordVo = updateRecord.toVo(newAnime);
    updateRecordVos.add(updateRecordVo);
    debugPrint("添加$updateRecordVo，长度=${updateRecordVos.length}");
    // 排序
    updateRecordVos
        .sort((a, b) => b.manualUpdateTime.compareTo(a.manualUpdateTime));
  }

  incrementUpdateOkCnt() {
    updateOkCnt++;
  }

  // 更新前重置为0
  resetUpdateOkCnt() {
    updateOkCnt.value = 0;
  }

  // 强制更新完成
  forceUpdateOk() {
    debugPrint("强制更新完成");
    updateOkCnt.value = needUpdateCnt.value;
  }

  setNeedUpdateCnt(int value) {
    needUpdateCnt.value = value;
  }

  // 直接往list中添加，并按更新时间排序，而不是重新查询数据库
  void addUpdateRecord(UpdateRecordVo updateRecordVo) {
    // 第二次刷新时，如果已经添加了(old、new、anime、time都一样)，则不进行添加
    if (updateRecordVos.contains(updateRecordVo)) {
      debugPrint("已有updateRecordVo=$updateRecordVo，跳过");
      return;
    }
    debugPrint("添加$updateRecordVo，长度=${updateRecordVos.length}");
    updateRecordVos.add(updateRecordVo);
    updateRecordVos
        .sort((a, b) => b.manualUpdateTime.compareTo(a.manualUpdateTime));
  }
}
