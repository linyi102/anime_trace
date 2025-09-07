import 'package:animetrace/components/anime_custom_cover.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/animation/fade_animated_switcher.dart';
import 'package:animetrace/components/operation_button.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/pages/anime_detail/anime_detail.dart';
import 'package:animetrace/pages/network/sources/pages/dedup/dedup_controller.dart';
import 'package:animetrace/utils/extensions/color.dart';
import 'package:get/get.dart';

/// 动漫去重页面
/// 去重依据：动漫名字
/// 也可添加首播时间一直的要求，这样就可以避免不是同一个动漫但名字相同的情况(未实现)
class DedupPage extends StatelessWidget {
  const DedupPage({super.key});

  DedupController get dedupController => Get.put(DedupController());

  @override
  Widget build(BuildContext context) {
    var scrollController = ScrollController();

    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await dedupController.refreshData();
        },
        child: GetBuilder(
          init: dedupController,
          id: DedupController.bodyId,
          builder: (_) => Stack(
            children: [
              FadeAnimatedSwitcher(
                loadOk: !dedupController.loading,
                destWidget: dedupController.totalCnt == 0
                    ? _buildEmptyWidget()
                    : Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                              child: SwitchListTile(
                                title: const Text("选中没有看过的动漫"),
                                value: dedupController
                                    .enableRetainAnimeHasProgress,
                                onChanged: (value) {
                                  dedupController.enableRetainAnimeHasProgress =
                                      value;
                                  if (value == true) {
                                    dedupController.retainAnimeHasProgress();
                                  } else {
                                    dedupController.clearSelected();
                                  }
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: Scrollbar(
                                controller: scrollController,
                                child: _buildAnimeList(scrollController)),
                          ),
                          if (dedupController.selectedIds.isNotEmpty)
                            _buildBottomBar(context)
                        ],
                      ),
              ),
              if (dedupController.totalCnt == 0)
                Align(
                    alignment: Alignment.bottomCenter,
                    child: OperationButton(
                      active: !dedupController.loading,
                      text: dedupController.loading ? "扫描中" : "重新扫描",
                      onTap: () {
                        dedupController.refreshData(showLoading: true);
                      },
                    )),
            ],
          ),
        ),
      ),
    );
  }

  _buildEmptyWidget() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: const Center(child: Text("没有同名动漫。")),
        ),
      ),
    );
  }

  _buildBottomBar(BuildContext context) {
    // 保留的含义不明确，如果有的同名动漫一个都没选，不应该都删除。因此只提供删除按钮
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      child: OperationButton(
        height: 70,
        text: "删除选中动漫",
        onTap: () => _showDialogDeleteSelectedAnimes(context),
      ),
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: GetBuilder(
        init: dedupController,
        id: DedupController.appBarId,
        builder: (_) => AppBar(
          title: Text(
            dedupController.selectedIds.isEmpty
                ? "动漫去重"
                : "${dedupController.selectedIds.length}/${dedupController.totalCnt}",
          ),
        ),
      ),
    );
  }

  _showDialogDeleteSelectedAnimes(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("删除"),
        content: const Text("确定要删除选中的动漫？"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);

                dedupController.deleteSelectedAnimes();
              },
              child: const Text("确定")),
        ],
      ),
    );
  }

  ListView _buildAnimeList(ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      // 避免没有占满时无法下拉刷新
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: dedupController.nameList.length,
      itemBuilder: (context, index) {
        var name = dedupController.nameList[index];
        return Column(
          children: [
            ListTile(
              title: Text(name, style: Theme.of(context).textTheme.titleMedium),
            ),
            if (dedupController.animeMap.containsKey(name))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: dedupController.animeMap[name]!.length,
                    itemBuilder: (context, index) {
                      var anime = dedupController.animeMap[name]![index];
                      bool selected =
                          dedupController.selectedIds.contains(anime.animeId);

                      return Column(
                        children: [
                          Stack(
                            children: [
                              InkWell(
                                onTap: () =>
                                    _enterAnimeDetailPage(context, name, index),
                                child: CustomAnimeCover(
                                  anime: anime,
                                  width: 100,
                                  style: AnimeCoverStyle.none(),
                                ),
                              ),
                              _buildSelectIcon(anime, selected, context)
                            ],
                          ),
                          Text(anime.getAnimeSource()),
                        ],
                      );
                    },
                  ),
                ),
              )
          ],
        );
      },
    );
  }

  void _enterAnimeDetailPage(
      BuildContext context,
      // Anime anime,
      String name,
      int index) {
    var anime = dedupController.animeMap[name]![index];
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return AnimeDetailPage(anime);
      },
    )).then((value) {
      // 若修改来源或封面后需要返回需要重新显示最新信息
      // 如果名字变了，虽然应该处理(具体方式为移除掉根据name找到list然后从中移除，如果只剩余1个，那么就删除该name的key)，但感觉没有必要，因此这里不进行处理

      // 错误(修改的是这个引用，map并没有变)：
      // anime = value;
      // 正确方式：
      dedupController.animeMap[name]![index] = value;
      // 重绘
      dedupController.update([DedupController.bodyId]);
    });
  }

  _buildSelectIcon(Anime anime, bool selected, BuildContext context) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: () {
          dedupController.invertSelectId(anime.animeId);
        },
        child: SizedBox(
          // 增大点击范围
          height: 35,
          width: 35,
          child: selected
              ? Center(
                  // 使用Center，确保Container设置的宽高生效
                  child: Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 18)))
              : Center(
                  child: Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // 添加白色边框，并为内部添加不透明度，避免白色封面导致看不见
                          color: Colors.black.withOpacityFactor(0.1),
                          border: Border.all(width: 1, color: Colors.white)))),
        ),
      ),
    );
  }
}
