import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_image.dart';
import 'package:flutter_test_future/pages/settings/series/form/view.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../../../components/search_app_bar.dart';
import '../../../../dao/series_dao.dart';
import '../../../../models/series.dart';
import '../../../../utils/delay_util.dart';
import '../../../../utils/log.dart';
import '../../../../widgets/common_scaffold_body.dart';
import '../detail/view.dart';
import 'logic.dart';

class SeriesManagePage extends StatelessWidget {
  const SeriesManagePage({this.enableSelectSeriesForAnime = false, Key? key})
      : super(key: key);
  final bool enableSelectSeriesForAnime;

  double get maxItemWidth => 240;
  SeriesManageLogic get logic => Get.put(SeriesManageLogic());

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(enableSelectSeriesForAnime ? "选择系列" : "系列管理"),
        automaticallyImplyLeading: enableSelectSeriesForAnime ? false : true,
      ),
      body: GetBuilder(
        init: logic,
        builder: (_) => CommonScaffoldBody(
            child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              child: _buildSearchBar(),
            ),
            Expanded(
              child: RefreshIndicator(
                child: _buildSeriesListView(context),
                onRefresh: () async {
                  await logic.getAllSeries();
                },
              ),
            )
          ],
        )),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  _buildSeriesListView(BuildContext context) {
    return GridView.builder(
      itemCount: logic.seriesList.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        mainAxisExtent: 165,
        maxCrossAxisExtent: maxItemWidth,
      ),
      itemBuilder: (context, index) {
        var series = logic.seriesList[index];
        return Card(
          child: InkWell(
            onTap: () {
              // 进入系列详情页
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeriesDetailPage(series),
                  )).then((value) async {
                // 更新该系列
                logic.seriesList[index] =
                    await SeriesDao.getSeriesById(series.id);
                logic.update();
              });
            },
            onLongPress: () {
              // 长按时也要弹出操作菜单，这样为动漫选择系列时也能重命名和删除了
              _showOpMenuDialog(context, series);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverlayCover(series),
                Row(
                  children: [
                    _buildInfo(series, context),
                    _buildMoreButton(context, series),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  _buildMoreButton(BuildContext context, Series series) {
    var borderRadius = BorderRadius.circular(99);
    return Column(
      children: [
        InkWell(
            borderRadius: borderRadius,
            onTap: () {
              _showOpMenuDialog(context, series);
            },
            child: SizedBox(
              height: 30,
              width: 30,
              child: Center(
                child: Icon(
                  Icons.more_horiz,
                  size: 20,
                  color: Theme.of(context).hintColor.withOpacity(0.4),
                ),
              ),
            )),
      ],
    );
  }

  _buildInfo(Series series, BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.only(left: 8, top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              series.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
            Text(
              '${series.animes.length}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildOverlayCover(Series series) {
    var imgCnt =
        // min(4, series.animes.length);
        series.animes.length;

    return SizedBox(
      height: 100,
      child: ListView.builder(
        itemCount: imgCnt,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => Container(
            padding: const EdgeInsets.only(right: 2),
            color: Colors.white,
            child: CommonImage(series.animes[index].animeCoverUrl)),
      ),
    );
  }

  _buildSearchBar() {
    return SearchAppBar(
      isAppBar: false,
      autofocus: false,
      inputController: logic.inputKeywordController,
      hintText: "搜索系列",
      onChanged: (kw) async {
        Log.info("搜索系列关键字：$kw");
        // 必须要查询数据库，而不是从已查询的全部数据中删除不含关键字的记录，否则会越删越少
        DelayUtil.delaySearch(() async {
          logic.seriesList = await SeriesDao.searchSeries(kw);
          logic.kw = kw; // 记录关键字
          logic.update();
        });
      },
      onEditingComplete: () {
        logic.kw = logic.inputKeywordController.text;
      },
      onTapClear: () async {
        logic.inputKeywordController.clear();
        logic.kw = "";
        logic.seriesList = await SeriesDao.getAllSeries();
      },
    );
  }

  _showOpMenuDialog(
    BuildContext context,
    Series series,
  ) {
    return showDialog(
        context: context,
        builder: (context) => SimpleDialog(
              children: [
                ListTile(
                  title: const Text("编辑"),
                  leading: const Icon(Icons.edit),
                  onTap: () {
                    Log.info("编辑系列：$series");
                    Navigator.of(context).pop();

                    int index = logic.seriesList
                        .indexWhere((element) => element == series);
                    _toModifySeriesFormPage(context, index);
                  },
                ),
                ListTile(
                  title: const Text("删除"),
                  leading: const Icon(Icons.delete_outline),
                  onTap: () {
                    Log.info("删除系列：$series");
                    Navigator.of(context).pop();
                    _showDialogConfirmDelete(context, series);
                  },
                )
              ],
            ));
  }

  _showDialogConfirmDelete(BuildContext context, Series series) {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("确定删除吗？"),
              content: Text("将要删除的系列：${series.name}"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("取消")),
                TextButton(
                    onPressed: () {
                      SeriesDao.delete(series.id);
                      logic.seriesList.remove(series);
                      Navigator.pop(context);
                    },
                    child: Text(
                      "删除",
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    )),
              ],
            ));
  }

  _buildFloatingActionButton(
    BuildContext context,
  ) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SeriesFormPage(),
            )).then((value) {
          logic.getAllSeries();
        });
      },
      child: const Icon(MingCuteIcons.mgc_add_line),
    );
  }

  _toModifySeriesFormPage(BuildContext context, int index) {
    Series series = logic.seriesList[index];
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeriesFormPage(
            series: series,
          ),
        )).then((value) {
      logic.update();
    });
  }
}
