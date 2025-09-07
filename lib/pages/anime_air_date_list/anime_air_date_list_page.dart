import 'package:animetrace/components/anime_custom_cover.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/components/anime_list_view.dart';
import 'package:animetrace/pages/anime_air_date_list/anime_air_date_list_controller.dart';
import 'package:get/get.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class AnimeAirDateListPage extends StatefulWidget {
  const AnimeAirDateListPage({super.key});

  @override
  State<AnimeAirDateListPage> createState() => _AnimeAirDateListPageState();
}

class _AnimeAirDateListPageState extends State<AnimeAirDateListPage> {
  final controller = Get.put(AnimeAirDateListController());
  final scrollController = ScrollController();
  final listController = ListController();

  @override
  void dispose() {
    Get.delete<AnimeAirDateListController>();
    scrollController.dispose();
    listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('时间线')),
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
                  listController.jumpToItem(
                    scrollController: scrollController,
                    index: controller.animeAirDateTimeItems
                        .indexWhere((e) => e.time == date),
                    alignment: 0,
                  );
                },
                child: Text(
                  getTimeTitle(date),
                  style: const TextStyle(fontSize: 12),
                ),
                style: const ButtonStyle(
                  visualDensity: VisualDensity(vertical: -2),
                  padding: WidgetStatePropertyAll(
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
      child: SuperListView.builder(
        controller: scrollController,
        listController: listController,
        itemCount: controller.animeAirDateTimeItems.length,
        itemBuilder: (context, index) {
          AnimeAirDateItem item = controller.animeAirDateTimeItems[index];
          return _buildAirDateItem(item);
        },
      ),
    );
  }

  Column _buildAirDateItem(AnimeAirDateItem airDateItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
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
        AnimeHorizontalListView(
          animes: airDateItem.animes,
          callback: () async => false,
          styleBuilder: (style) => style.copyWith(
            progressLinearPlacement: Placement.none,
            progressNumberPlacement: Placement.none,
          ),
        ),
      ],
    );
  }

  String getTimeTitle(DateTime time) {
    if (time == controller.unknownAirDate) {
      return '未知';
    }
    return '${time.year} 年 ${time.month} 月';
  }
}
