import 'package:flutter/foundation.dart';
import 'package:flutter_test_future/models/enum/anime_area.dart';
import 'package:flutter_test_future/models/enum/anime_category.dart';
import 'package:flutter_test_future/models/enum/play_status.dart';
import 'package:flutter_test_future/models/label.dart';

class LocalSelectFilter {
  String? checklist;
  List<Label> labels;
  int? rate;
  AnimeArea? area;
  AnimeCategory? category;
  int? airDateYear;
  int? airDateMonth;
  PlayStatus? playStatus;
  LocalSelectFilter({
    this.checklist,
    this.labels = const [],
    this.rate,
    this.area,
    this.category,
    this.airDateYear,
    this.airDateMonth,
    this.playStatus,
  });

  LocalSelectFilter copyWith({
    String? checklist,
    List<Label>? labels,
    int? rate,
    AnimeArea? area,
    AnimeCategory? category,
    int? airDateYear,
    int? airDateMonth,
    PlayStatus? playStatus,
  }) {
    return LocalSelectFilter(
      checklist: checklist ?? this.checklist,
      labels: labels ?? this.labels,
      rate: rate ?? this.rate,
      area: area ?? this.area,
      category: category ?? this.category,
      airDateYear: airDateYear ?? this.airDateYear,
      airDateMonth: airDateMonth ?? this.airDateMonth,
      playStatus: playStatus ?? this.playStatus,
    );
  }

  @override
  String toString() {
    return 'LocalSelectFilter(checklist: $checklist, labels: $labels, rate: $rate, area: $area, category: $category, airDateYear: $airDateYear, airDateMonth: $airDateMonth, playStatus: $playStatus)';
  }

  @override
  bool operator ==(covariant LocalSelectFilter other) {
    if (identical(this, other)) return true;

    return other.checklist == checklist &&
        listEquals(other.labels, labels) &&
        other.rate == rate &&
        other.area == area &&
        other.category == category &&
        other.airDateYear == airDateYear &&
        other.airDateMonth == airDateMonth &&
        other.playStatus == playStatus;
  }

  @override
  int get hashCode {
    return checklist.hashCode ^
        labels.hashCode ^
        rate.hashCode ^
        area.hashCode ^
        category.hashCode ^
        airDateYear.hashCode ^
        airDateMonth.hashCode ^
        playStatus.hashCode;
  }
}
