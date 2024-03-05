import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_horizontal_cover.dart';
import 'package:flutter_test_future/pages/anime_air_date_list/anime_air_date_list_controller.dart';
import 'package:get/get.dart';

class AnimeAirDateListPage extends StatefulWidget {
  const AnimeAirDateListPage({super.key});

  @override
  State<AnimeAirDateListPage> createState() => _AnimeAirDateListPageState();
}

class _AnimeAirDateListPageState extends State<AnimeAirDateListPage> {
  final controller = Get.put(AnimeAirDateListController());
  final scrollController = ScrollController();

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
        child: Scrollbar(
          controller: scrollController,
          child: GetBuilder(
            init: controller,
            builder: (_) => _buildAirDateListView(),
          ),
        ),
      ),
    );
  }

  ListView _buildAirDateListView() {
    return ListView.builder(
      controller: scrollController,
      itemCount: controller.animeAirDateTimeItems.length,
      itemBuilder: (context, index) {
        AnimeAirDateItem animeTimeItem =
            controller.animeAirDateTimeItems[index];
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
                        getTimeTitle(animeTimeItem),
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
              animes: animeTimeItem.animes,
              callback: () async => false,
            ),
          ],
        );
      },
    );
  }

  String getTimeTitle(AnimeAirDateItem animeTimeItem) {
    if (animeTimeItem.time == controller.unknownAirDate) {
      return '未知';
    }
    return '${animeTimeItem.time.year} 年 ${animeTimeItem.time.month} 月';
  }
}
