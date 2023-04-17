import 'package:flutter/material.dart';
import 'package:flutter_test_future/dao/label_dao.dart';
import 'package:get/get.dart';

import '../models/label.dart';

class LabelsController extends GetxController {
  // 所有标签
  RxList<Label> labels = RxList.empty();

  // 文本输入控制器，放在这里是为了避免重绘时丢失
  var inputKeywordController = TextEditingController();

  // 搜索输入关键字(因为搜索后退出标签管理界面时，labels不再是数据库全部标签，所以再进入时要显示当前关键字)
  String kw = "";

  // RxBool isOk = false.obs;
  // RxInt cnt = 0.obs;

  @override
  void onInit() {
    super.onInit();
    getAllLabels();
  }

  @override
  void dispose() {
    inputKeywordController.dispose();
    super.dispose();
  }

  // 还原数据后，需要重新获取所有标签
  void getAllLabels() async {
    labels.value = await LabelDao.getAllLabels();
  }
}
