import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/params/page_params.dart';
import 'package:flutter_test_future/classes/vo/update_record_vo.dart';
import 'package:flutter_test_future/utils/dao/update_record_dao.dart';
import 'package:get/get.dart';

class UpdateRecordController extends GetxController {
  PageParams pageParams = PageParams(0, 5); // 动漫列表页刷新时也要传入该变量
  bool initOk = false; // 第一次进入该页面时initState中调用了UpdateData，下次再进入就不需要了

  RxList<UpdateRecordVo> updateRecordVos = RxList.empty();
  updateData() async {
    initOk = true;
    // 重新获取数据库内容
    updateRecordVos = (await UpdateRecordDao.findAll(pageParams)).obs;
  }
}
