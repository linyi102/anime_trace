import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/params/page_params.dart';
import 'package:flutter_test_future/classes/vo/update_record_vo.dart';
import 'package:flutter_test_future/utils/dao/update_record_dao.dart';
import 'package:get/get.dart';

class UpdateRecordController extends GetxController {
  PageParams pageParams = PageParams(0, 10); // 动漫列表页刷新时也要传入该变量
  bool initOk = false; // 第一次进入该页面时initState中调用了UpdateData，下次再进入就不需要了
  RxInt updateOkCnt = 0.obs, needUpdateCnt = 0.obs;

  RxList<UpdateRecordVo> updateRecordVos = RxList.empty();

  Future<void> updateData() async {
    debugPrint("重新获取数据库内容并覆盖");
    pageParams.pageIndex = 0; // 应该重置为0
    updateRecordVos.value = await UpdateRecordDao.findAll(pageParams);
    initOk = true;
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

  setNeedUpdateCnt(int value) {
    needUpdateCnt.value = value;
  }
}