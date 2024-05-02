import 'package:flutter_test_future/models/enum/anime_area.dart';
import 'package:flutter_test_future/models/enum/anime_category.dart';
import 'package:flutter_test_future/models/enum/play_status.dart';
import 'package:flutter_test_future/models/enum/search_source.dart';
import 'package:flutter_test_future/models/label.dart';

class LocalSelectFilter {
  String? keyword;
  String? checklist;
  late List<Label> labels;
  int? rate;
  AnimeArea? area;
  AnimeCategory? category;
  int? airDateYear;
  int? airDateMonth;
  PlayStatus? playStatus;
  AnimeSource? source;
  LocalSelectFilter({
    this.keyword,
    this.checklist,
    List<Label>? labels,
    this.rate,
    this.area,
    this.category,
    this.airDateYear,
    this.airDateMonth,
    this.playStatus,
    this.source,
  }) {
    this.labels = labels ?? [];
  }

  String? get airDate {
    if (airDateYear == null) return null;
    if (airDateMonth == null) return airDateYear.toString();
    return '$airDateYear-${airDateMonth.toString().padLeft(2, '0')}';
  }

  LocalSelectFilter copyWith({
    String? keyword,
    String? checklist,
    List<Label>? labels,
    int? rate,
    AnimeArea? area,
    AnimeCategory? category,
    int? airDateYear,
    int? airDateMonth,
    PlayStatus? playStatus,
    AnimeSource? source,
  }) {
    return LocalSelectFilter(
      keyword: keyword ?? this.keyword,
      checklist: checklist ?? this.checklist,
      labels: labels ?? this.labels,
      rate: rate ?? this.rate,
      area: area ?? this.area,
      category: category ?? this.category,
      airDateYear: airDateYear ?? this.airDateYear,
      airDateMonth: airDateMonth ?? this.airDateMonth,
      playStatus: playStatus ?? this.playStatus,
      source: source ?? this.source,
    );
  }

  @override
  String toString() {
    return 'LocalSelectFilter(keyword: $keyword, checklist: $checklist, labels: $labels, rate: $rate, area: $area, category: $category, airDateYear: $airDateYear, airDateMonth: $airDateMonth, playStatus: $playStatus, source: $source)';
  }

  @override
  bool operator ==(covariant LocalSelectFilter other) {
    if (identical(this, other)) return true;

    return other.keyword == keyword &&
        other.checklist == checklist &&
        other.labels == labels &&
        other.rate == rate &&
        other.area == area &&
        other.category == category &&
        other.airDateYear == airDateYear &&
        other.airDateMonth == airDateMonth &&
        other.playStatus == playStatus &&
        other.source == source;
  }

  @override
  int get hashCode {
    return keyword.hashCode ^
        checklist.hashCode ^
        labels.hashCode ^
        rate.hashCode ^
        area.hashCode ^
        category.hashCode ^
        airDateYear.hashCode ^
        airDateMonth.hashCode ^
        playStatus.hashCode ^
        source.hashCode;
  }
}
