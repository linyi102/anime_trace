import 'package:get/get.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test_future/dao/history_dao.dart';
import 'package:flutter_test_future/models/history_plus.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

enum HistoryLabel {
  year("年", MingCuteIcons.mgc_calendar_line),
  month("月", MingCuteIcons.mgc_calendar_line),
  day("日", MingCuteIcons.mgc_calendar_line);

  final String title;
  final IconData iconData;
  const HistoryLabel(this.title, this.iconData);
}

class HistoryView {
  HistoryLabel label;
  PageParams pageParams;
  int dateLength; // 用于匹配数据库中日期xxxx-xx-xx的子串
  List<HistoryPlus> historyRecords = [];
  ScrollController scrollController = ScrollController();

  HistoryView(
      {required this.label,
      required this.pageParams,
      required this.dateLength});
}

class HistoryController extends GetxController {
  static HistoryController get to => Get.find();

  List<HistoryView> views = [
    HistoryView(
        label: HistoryLabel.year,
        pageParams: PageParams(pageIndex: 0, pageSize: 5),
        dateLength: 4),
    HistoryView(
        label: HistoryLabel.month,
        pageParams: PageParams(pageIndex: 0, pageSize: 10),
        dateLength: 7),
    HistoryView(
        label: HistoryLabel.day,
        pageParams: PageParams(pageIndex: 0, pageSize: 15),
        dateLength: 10)
  ];
  int selectedViewIndex = SPUtil.getInt("selectedViewIndexInHistoryPage",
      defaultValue: 1); // 默认为1，也就是月视图
  bool loadOk = false;
  bool initOk = false;
  late HistoryLabel selectedHistoryLabel;

  @override
  void onInit() {
    selectedHistoryLabel = views[selectedViewIndex].label;
    loadData();
    // 下次打开历史页，则会根据initOk来确定是否需要refreshData
    initOk = true;
    super.onInit();
  }

  Future<void> refreshData() {
    Log.info("刷新历史页");
    // 恢复为初始状态
    for (var view in views) {
      // 初始页号
      view.pageParams.pageIndex = view.pageParams.baseIndex;
      // 显示旧数据，不要清空
      // view.historyRecords.clear();
    }
    // update();
    // 加载数据
    return loadData();
  }

  Future<void> loadData() async {
    // await Future.delayed(const Duration(seconds: 1));

    views[selectedViewIndex].historyRecords =
        await HistoryDao.getHistoryPageable(
            pageParams: views[selectedViewIndex].pageParams,
            dateLength: views[selectedViewIndex].dateLength);
    loadOk = true;
    update();
  }

  loadMoreData() async {
    Log.info("加载更多数据");
    views[selectedViewIndex].historyRecords.addAll(
        await HistoryDao.getHistoryPageable(
            pageParams: views[selectedViewIndex].pageParams,
            dateLength: views[selectedViewIndex].dateLength));
    update();
  }
}
