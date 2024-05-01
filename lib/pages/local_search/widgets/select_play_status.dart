import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/enum/play_status.dart';
import 'package:flutter_test_future/pages/local_search/controllers/local_search_controller.dart';
import 'package:flutter_test_future/pages/local_search/models/local_select_filter.dart';
import 'package:get/get.dart';

class SelectPlayStatusView extends StatefulWidget {
  const SelectPlayStatusView({super.key});
  @override
  State<SelectPlayStatusView> createState() => _SelectPlayStatusViewState();
}

class _SelectPlayStatusViewState extends State<SelectPlayStatusView> {
  LocalSelectFilter get localSelectFilter =>
      LocalSearchController.to.localSelectFilter;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: LocalSearchController.to,
      builder: (_) => Scaffold(
        body: ListView.builder(
          itemCount: PlayStatus.values.length,
          itemBuilder: (context, index) {
            final playStatus = PlayStatus.values[index];
            return RadioListTile<PlayStatus>(
                title: Text(playStatus.text),
                toggleable: true,
                value: playStatus,
                groupValue: localSelectFilter.playStatus,
                onChanged: (value) {
                  LocalSearchController.to.setSelectedLabelTitle(
                      LocalSearchController.to.playStatusFilter, value?.text);

                  setState(() {
                    localSelectFilter.playStatus = value;
                  });
                });
          },
        ),
      ),
    );
  }
}
