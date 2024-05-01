import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_rating_bar.dart';
import 'package:flutter_test_future/pages/local_search/controllers/local_search_controller.dart';
import 'package:flutter_test_future/pages/local_search/models/local_select_filter.dart';
import 'package:get/get.dart';

class SelectRateView extends StatefulWidget {
  const SelectRateView({super.key});

  @override
  State<SelectRateView> createState() => _SelectRateViewState();
}

class _SelectRateViewState extends State<SelectRateView> {
  LocalSelectFilter get localSelectFilter =>
      LocalSearchController.to.localSelectFilter;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: LocalSearchController.to,
      builder: (_) => Scaffold(
        body: Center(
            child: AnimeRatingBar(
          rate: localSelectFilter.rate ?? 0,
          iconSize: 28,
          onRatingUpdate: (value) {
            LocalSearchController.to.setSelectedLabelTitle(
                LocalSearchController.to.rateFilter, value.toInt().toString());

            localSelectFilter.rate = value.toInt();
            LocalSearchController.to.update();
          },
        )),
      ),
    );
  }
}
