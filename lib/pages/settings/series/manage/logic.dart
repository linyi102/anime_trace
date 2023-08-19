import 'package:flutter/material.dart';
import 'package:flutter_test_future/dao/series_dao.dart';
import 'package:flutter_test_future/models/series.dart';
import 'package:get/get.dart';

class SeriesManageLogic extends GetxController {
  // 所有标签
  List<Series> seriesList = [];

  // 文本输入控制器，放在这里是为了避免重绘时丢失
  var inputKeywordController = TextEditingController();

  String kw = "";

  @override
  void onInit() {
    super.onInit();
    getAllSeries();
  }

  @override
  void dispose() {
    inputKeywordController.dispose();
    super.dispose();
  }

  // 还原数据后，需要重新获取所有系列
  getAllSeries() async {
    seriesList = await SeriesDao.getAllSeries();
    update();
  }
}
