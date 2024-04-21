import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_horizontal_cover.dart';
import 'package:flutter_test_future/models/anime_grid_cover_config.dart';
import 'package:flutter_test_future/pages/anime_air_date_list/anime_air_date_list_controller.dart';
import 'package:get/get.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

class AnimeAirDateListPage extends StatefulWidget {
  const AnimeAirDateListPage({super.key});

  @override
  State<AnimeAirDateListPage> createState() => _AnimeAirDateListPageState();
}

class _AnimeAirDateListPageState extends State<AnimeAirDateListPage> {
  final controller = Get.put(AnimeAirDateListController());
  final scrollController = ScrollController();
  late final observerController =
      ListObserverController(controller: scrollController);

  @override
  void dispose() {
    Get.delete<AnimeAirDateListController>();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.loadAllAnimes();
        },
        child: GetBuilder(
          init: controller,
          builder: (_) => Column(
            children: [
              _buildDateSelector(),
              Expanded(child: _buildAirDateListView()),
            ],
          ),
        ),
      ),
    );
  }

  _buildDateSelector() {
    return Container(
      height: 50,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        scrollDirection: Axis.horizontal,
        children: [
          for (final date in controller.allAirDate)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: OutlinedButton(
                onPressed: () {
                  observerController.jumpTo(
                    index: controller.animeAirDateTimeItems
                        .indexWhere((e) => e.time == date),
                  );
                },
                child: Text(
                  getTimeTitle(date),
                  style: const TextStyle(fontSize: 12),
                ),
                style: const ButtonStyle(
                  visualDensity: VisualDensity(vertical: -2),
                  padding: MaterialStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 10)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  _buildAirDateListView() {
    return Scrollbar(
      controller: scrollController,
      child: ListViewObserver(
        controller: observerController,
        child: ListView.builder(
          controller: scrollController,
          itemCount: controller.animeAirDateTimeItems.length,
          itemBuilder: (context, index) {
            AnimeAirDateItem item = controller.animeAirDateTimeItems[index];
            return _buildAirDateItem(item);
          },
        ),
      ),
    );
  }

  Column _buildAirDateItem(AnimeAirDateItem airDateItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    getTimeTitle(airDateItem.time),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // const Spacer(),
              // Text(
              //   '全部',
              //   style: Theme.of(context).textTheme.bodySmall,
              // ),
            ],
          ),
        ),
        AnimeHorizontalCover(
          animes: airDateItem.animes,
          callback: () async => false,
          coverConfig: airDateItem.time == controller.recentWatchDate
              ? AnimeGridCoverConfig.allShow()
              : AnimeGridCoverConfig.noneShow().copyWith(
                  showCover: true,
                  showName: true,
                ),
        ),
      ],
    );
  }

  String getTimeTitle(DateTime time) {
    if (time == controller.unknownAirDate) {
      return '未知';
    } else if (time == controller.recentWatchDate) {
      return '最近观看';
    }
    return '${time.year} 年 ${time.month} 月';
  }
}
