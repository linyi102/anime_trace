import 'package:flutter/material.dart';
import 'package:animetrace/components/anime_rating_bar.dart';
import 'package:animetrace/pages/local_search/controllers/local_search_controller.dart';
import 'package:animetrace/pages/local_search/models/local_select_filter.dart';
import 'package:get/get.dart';

class SelectRateView extends StatefulWidget {
  const SelectRateView({required this.localSearchController, super.key});
  final LocalSearchController localSearchController;

  @override
  State<SelectRateView> createState() => _SelectRateViewState();
}

class _SelectRateViewState extends State<SelectRateView> {
  LocalSelectFilter get localSelectFilter =>
      widget.localSearchController.localSelectFilter;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: widget.localSearchController,
      tag: widget.localSearchController.tag,
      builder: (_) => Scaffold(
        body: Center(
            child: AnimeRatingBar(
          rate: localSelectFilter.rate ?? 0,
          iconSize: 28,
          onRatingUpdate: (value) {
            widget.localSearchController.setRate(value.toInt());
          },
        )),
      ),
    );
  }
}
