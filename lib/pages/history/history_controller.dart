import 'package:get/get.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:animetrace/dao/history_dao.dart';
import 'package:animetrace/models/history_plus.dart';
import 'package:animetrace/models/params/page_params.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/sp_util.dart';
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

  bool loadOk = false;

  int curViewIndex =
      SPUtil.getInt("selectedViewIndexInHistoryPage", defaultValue: 1);
  HistoryLabel get selectedHistoryLabel => views[curViewIndex].label;

  PageController? pageController;

  @override
  void onClose() {
    for (var view in views) {
      view.scrollController.dispose();
    }
    pageController?.dispose();
    super.onClose();
  }

  Future<void> loadData() async {
    // 切换导航后重新渲染State中的PageView时，展示的页号始终是initialPage(可能和curViewIndex不对应)，所以此处重新创建PageController
    pageController?.dispose();
    pageController = PageController(initialPage: curViewIndex);
    for (var view in views) {
      // 重置页号
      view.pageParams.pageIndex = view.pageParams.baseIndex;
      view.historyRecords = await HistoryDao.getHistoryPageable(
          pageParams: view.pageParams, dateLength: view.dateLength);
    }
    loadOk = true;
    update();
  }

  Future<void> loadMoreData() async {
    AppLog.debug("加载更多数据");
    views[curViewIndex].historyRecords.addAll(
        await HistoryDao.getHistoryPageable(
            pageParams: views[curViewIndex].pageParams,
            dateLength: views[curViewIndex].dateLength));
    update();
  }
}
