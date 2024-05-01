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
    icon: Icons.category_rounded,
    filterView: const SelectCategoryView(),
  );

  final airDateFilter = LocalSearchFilter(
    label: '首播时间',
    icon: Icons.date_range,
    filterView: const SelectAirDateView(),
  );

  final playStatusFilter = LocalSearchFilter(
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
    playStatusFilter,
  ];

  void resetAll() {
    localSelectFilter = LocalSelectFilter();
    for (final e in filters) {
      e.selectedLabel = '';
    }
    update();
  }

  void reset(LocalSearchFilter filter) {
    if (filter == checklistFilter) {
      localSelectFilter.checklist = null;
    } else if (filter == labelFilter) {
      localSelectFilter.labels.clear();
    } else if (filter == rateFilter) {
      localSelectFilter.rate = null;
    } else if (filter == areaFilter) {
      localSelectFilter.area = null;
    } else if (filter == categoryFilter) {
      localSelectFilter.category = null;
    } else if (filter == airDateFilter) {
      localSelectFilter.airDateYear = null;
      localSelectFilter.airDateMonth = null;
    } else if (filter == playStatusFilter) {
      localSelectFilter.playStatus = null;
    }
    setSelectedLabelTitle(filter, null);
    search();
  }

  search() {
    Log.info(localSelectFilter);
  }

  void setSelectedLabelTitle(LocalSearchFilter filter, String? selectedLabel) {
    filter.selectedLabel = selectedLabel ?? '';
    update();
  }
}
