import 'package:flutter/material.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/enum/anime_area.dart';
import 'package:flutter_test_future/models/enum/anime_category.dart';
import 'package:flutter_test_future/models/enum/play_status.dart';
import 'package:flutter_test_future/models/enum/search_source.dart';
import 'package:flutter_test_future/models/label.dart';
import 'package:flutter_test_future/pages/local_search/models/local_search_filter.dart';
import 'package:flutter_test_future/pages/local_search/models/local_select_filter.dart';
import 'package:flutter_test_future/pages/local_search/widgets/select_air_date.dart';
import 'package:flutter_test_future/pages/local_search/widgets/select_area.dart';
import 'package:flutter_test_future/pages/local_search/widgets/select_category.dart';
import 'package:flutter_test_future/pages/local_search/widgets/select_checklist.dart';
import 'package:flutter_test_future/pages/local_search/widgets/select_label.dart';
import 'package:flutter_test_future/pages/local_search/widgets/select_play_status.dart';
import 'package:flutter_test_future/pages/local_search/widgets/select_rate.dart';
import 'package:flutter_test_future/pages/local_search/widgets/select_source.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class LocalSearchController extends GetxController {
  bool searchOk = false;
  List<Anime> animes = [];
  LocalSelectFilter localSelectFilter = LocalSelectFilter();

  late final _checklistFilter = LocalSearchFilter(
    label: '清单',
    icon: Icons.checklist_rounded,
    filterView: SelectChecklistView(localSearchController: this),
  );

  late final _labelFilter = LocalSearchFilter(
    label: '标签',
    icon: MingCuteIcons.mgc_tag_2_fill,
    filterView: SelectLabelView(localSearchController: this),
  );

  late final _rateFilter = LocalSearchFilter(
    label: '星级',
    icon: Icons.star,
    filterView: SelectRateView(localSearchController: this),
  );

  late final _areaFilter = LocalSearchFilter(
    label: '地区',
    icon: Icons.location_on,
    filterView: SelectAreaView(localSearchController: this),
  );

  late final _categoryFilter = LocalSearchFilter(
    label: '类别',
    icon: Icons.category_rounded,
    filterView: SelectCategoryView(localSearchController: this),
  );

  late final _airDateFilter = LocalSearchFilter(
    label: '首播时间',
    icon: Icons.date_range,
    filterView: SelectAirDateView(localSearchController: this),
  );

  late final _playStatusFilter = LocalSearchFilter(
    label: '播放状态',
    icon: Icons.stacked_bar_chart,
    filterView: SelectPlayStatusView(localSearchController: this),
  );

  late final _sourceFilter = LocalSearchFilter(
    label: '搜索源',
    icon: Icons.south_america_rounded,
    filterView: SelectSourceView(localSearchController: this),
  );

  late List<LocalSearchFilter> filters = [
    _checklistFilter,
    _labelFilter,
    _rateFilter,
    _areaFilter,
    _categoryFilter,
    _airDateFilter,
    _playStatusFilter,
    _sourceFilter,
  ];

  void resetAll() {
    localSelectFilter = LocalSelectFilter();
    for (final e in filters) {
      e.selectedLabel = '';
    }
    update();
  }

  void reset(LocalSearchFilter filter) {
    if (filter == _checklistFilter) {
      localSelectFilter.checklist = null;
    } else if (filter == _labelFilter) {
      localSelectFilter.labels.clear();
    } else if (filter == _rateFilter) {
      localSelectFilter.rate = null;
    } else if (filter == _areaFilter) {
      localSelectFilter.area = null;
    } else if (filter == _categoryFilter) {
      localSelectFilter.category = null;
    } else if (filter == _airDateFilter) {
      localSelectFilter.airDateYear = null;
      localSelectFilter.airDateMonth = null;
    } else if (filter == _playStatusFilter) {
      localSelectFilter.playStatus = null;
    } else if (filter == _sourceFilter) {
      localSelectFilter.source = null;
    }
    _setSelectedLabelTitle(filter, null);
    search();
  }

  Future<void> search() async {
    Log.info(localSelectFilter);
    searchOk = false;
    update();

    animes = await AnimeDao.complexSearch(localSelectFilter);
    searchOk = true;
    update();
  }

  void setKeyword(String? keyword) {
    localSelectFilter.keyword = keyword;
    search();
  }

  void setChecklist(String? checklist) {
    localSelectFilter.checklist = checklist;
    _setSelectedLabelTitle(_checklistFilter, checklist);
  }

  void setLabels(List<Label>? labels) {
    localSelectFilter.labels = labels ?? [];
    _setSelectedLabelTitle(
        _labelFilter, labels?.map((e) => e.nameWithoutEmoji).join(' & '));
  }

  void setRate(int? rate) {
    localSelectFilter.rate = rate;
    _setSelectedLabelTitle(_rateFilter, rate?.toInt().toString());
  }

  void setArea(AnimeArea? area) {
    localSelectFilter.area = area;
    _setSelectedLabelTitle(_areaFilter, area?.label);
  }

  void setCategory(AnimeCategory? category) {
    localSelectFilter.category = category;
    _setSelectedLabelTitle(_categoryFilter, category?.label);
  }

  void setAirDate(int? year, int? month) {
    localSelectFilter.airDateYear = year;
    localSelectFilter.airDateMonth = month;
    final label = () {
      if (year == null && month == null) return null;
      if (year != null && month == null) return '$year';
      return '$year-${month.toString().padLeft(2, '0')}';
    }();
    _setSelectedLabelTitle(_airDateFilter, label);
  }

  void setPlayStatus(PlayStatus? playStatus) {
    localSelectFilter.playStatus = playStatus;
    _setSelectedLabelTitle(_playStatusFilter, playStatus?.text);
  }

  void setSource(AnimeSource? source) {
    localSelectFilter.source = source;
    _setSelectedLabelTitle(_sourceFilter, source?.label);
  }

  void _setSelectedLabelTitle(LocalSearchFilter filter, String? selectedLabel) {
    filter.selectedLabel = selectedLabel ?? '';
    update();
    search();
  }
}
