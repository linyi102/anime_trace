import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/local_search/models/local_search_filter.dart';
import 'package:flutter_test_future/pages/local_search/models/local_select_filter.dart';
import 'package:flutter_test_future/pages/local_search/widgets/select_air_date.dart';
import 'package:flutter_test_future/pages/local_search/widgets/select_area.dart';
import 'package:flutter_test_future/pages/local_search/widgets/select_category.dart';
import 'package:flutter_test_future/pages/local_search/widgets/select_checklist.dart';
import 'package:flutter_test_future/pages/local_search/widgets/select_label.dart';
import 'package:flutter_test_future/pages/local_search/widgets/select_play_status.dart';
import 'package:flutter_test_future/pages/local_search/widgets/select_rate.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class LocalSearchController extends GetxController {
  static LocalSearchController to = Get.find();

  LocalSelectFilter localSelectFilter = LocalSelectFilter();

  final checklistFilter = LocalSearchFilter(
    label: '清单',
    icon: Icons.checklist_rounded,
    filterView: const SelectChecklistView(),
  );

  final labelFilter = LocalSearchFilter(
    label: '标签',
    icon: MingCuteIcons.mgc_tag_2_fill,
    filterView: const SelectLabelView(),
  );

  final rateFilter = LocalSearchFilter(
    label: '星级',
    icon: Icons.star,
    filterView: const SelectRateView(),
  );

  final areaFilter = LocalSearchFilter(
    label: '地区',
    icon: Icons.location_on,
    filterView: const SelectAreaView(),
  );

  final categoryFilter = LocalSearchFilter(
    label: '类别',
    icon: Icons.category,
    filterView: const SelectCategoryView(),
  );

  final airDateFilter = LocalSearchFilter(
    label: '首播时间',
    icon: Icons.date_range,
    filterView: const SelectAirDateView(),
  );

  final playStatus = LocalSearchFilter(
    label: '播放状态',
    icon: Icons.stacked_bar_chart,
    filterView: const SelectPlayStatusView(),
  );

  late List<LocalSearchFilter> filters = [
    checklistFilter,
    labelFilter,
    rateFilter,
    areaFilter,
    categoryFilter,
    airDateFilter,
    playStatus,
  ];

  void reset() {
    localSelectFilter = LocalSelectFilter();
    for (final e in filters) {
      e.selectedLabel = '';
    }
    update();
  }

  search() {
    Log.info(localSelectFilter);
  }

  void setSelectedLabelTitle(LocalSearchFilter filter, String? selectedLabel) {
    filter.selectedLabel = selectedLabel ?? '';
    update();
  }
}
