import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/settings/series/manage/logic.dart';
import 'package:get/get.dart';

class IgnoredSeriesListView extends StatelessWidget {
  const IgnoredSeriesListView({required this.logic, super.key});
  final SeriesManageLogic logic;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: logic,
      tag: logic.tag,
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('忽略系列'),
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          centerTitle: true,
        ),
        body: ListView.builder(
          itemCount: logic.ignoredSerieNames.length,
          itemBuilder: (context, index) {
            final seriesName = logic.ignoredSerieNames[index];
            return ListTile(
              title: Text(seriesName),
              trailing: IconButton(
                onPressed: () async {
                  await logic.cancelIgnoreSeries(seriesName);
                  if (logic.ignoredSerieNames.isEmpty) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.close, size: 20),
                splashRadius: 18,
              ),
            );
          },
        ),
      ),
    );
  }
}
