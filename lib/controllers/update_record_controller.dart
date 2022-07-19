import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/params/page_params.dart';
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
        .sort((a, b) => a.manualUpdateTime.compareTo(b.manualUpdateTime));
  }
}
