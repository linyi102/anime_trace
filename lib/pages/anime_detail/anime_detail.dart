import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/global.dart';

import 'package:flutter_test_future/pages/anime_detail/controllers/anime_controller.dart';
import 'package:flutter_test_future/controllers/labels_controller.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/widgets/app_bar.dart';
import 'package:flutter_test_future/pages/anime_detail/widgets/episode.dart';
import 'package:flutter_test_future/pages/anime_detail/widgets/info.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:get/get.dart';

class AnimeDetailPage extends StatefulWidget {
  final Anime anime;

  const AnimeDetailPage(
    this.anime, {
    Key? key,
  }) : super(key: key);

  @override
  _AnimeDetailPageState createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  late final AnimeController animeController; // 动漫详细页的动漫
  final LabelsController labelsController = Get.find(); // 动漫详细页的标签

  Anime get _anime => animeController.anime;
  String tag = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();

    // 动漫没有收藏的两种情况：
    // 如果传入的动漫id>0，或者传入的动漫id>0，但在数据库中找不到

    animeController = Get.put(
      AnimeController(tag),
      // 用id作为tag，当重复进入相同id的动漫时信息仍相同。但是对于没有收藏的动漫，会因为id相同从而当作一样的动漫
      // 也不能用动漫链接，因为有些是自定义动漫
      // tag: widget.anime.animeId.toString(),
      tag: tag,
    );

    animeController.loadAnime(widget.anime);
  }

  @override
  void dispose() {
    Get.delete<AnimeController>();
    super.dispose();
  }

  // 用于传回到动漫列表页
  void _popPage() {
    _anime.checkedEpisodeCnt = 0;
    for (var episode in animeController.episodes) {
      if (episode.isChecked()) _anime.checkedEpisodeCnt++;
    }
    Navigator.pop(context, _anime);

    // 清空标签和集信息
    animeController.popPage();
  }

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);

    return WillPopScope(
      onWillPop: () async {
        Log.info("按返回键，返回anime");
        _popPage();
        // 返回的_anime用到了id(列表页面和搜索页面)和name(爬取页面)
        // 完成集数因为切换到小的回顾号会导致不是最大回顾号完成的集数，所以那些页面会通过传回的id来获取最新动漫信息
        Log.info("返回true");
        return true;
      },
      child: Scaffold(
        body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Stack(children: [
              GetBuilder<AnimeController>(
                id: animeController.detailPageId,
                tag: tag,
                init: animeController,
                initState: (_) {},
                builder: (_) {
                  Log.info("build ${animeController.detailPageId}");

                  if (animeController.loadingAnime) {
                    return Scaffold(
                      appBar: AppBar(
                          leading: IconButton(
                              onPressed: _popPage,
                              icon: const Icon(Icons.arrow_back))),
                      body: const LoadingWidget(center: true),
                    );
                  }
                  if (Global.isLandscape(context)) {
                    return _buildLandscapeView();
                  }

                  return _buildRefreshAnimeIndicator(
                    child: CustomScrollView(
                      slivers: [
                        // 构建顶部栏
                        AnimeDetailAppBar(
                          animeController: animeController,
                          popPage: _popPage,
                        ),
                        // 构建动漫信息(名字、评分、其他信息)
                        AnimeDetailInfo(animeController: animeController),
                        // const SliverToBoxAdapter(child: CommonDivider()),
                        // 构建主体(集信息页)
                        AnimeDetailEpisodeInfo(animeController: animeController)
                      ],
                    ),
                  );
                },
              ),
              Obx(() => _buildButtonsBarAboutEpisodeMulti())
            ])),
      ),
    );
  }

  _buildRefreshAnimeIndicator({required Widget child}) {
    return RefreshIndicator(
      onRefresh: () async {
        // 使用await后，只有当获取信息完成后，加载圈才会消失
        await animeController.climbAnimeInfo(context);
      },
      child: child,
    );
  }

  Row _buildLandscapeView() {
    return Row(
      children: [
        Expanded(
          child: _buildRefreshAnimeIndicator(
            child: CustomScrollView(
              slivers: [
                AnimeDetailAppBar(
                  animeController: animeController,
                  popPage: _popPage,
                ),
                AnimeDetailInfo(animeController: animeController),
              ],
            ),
          ),
        ),
        if (_anime.isCollected())
          Expanded(
            child: CustomScrollView(
              slivers: [
                AnimeDetailEpisodeInfo(animeController: animeController)
              ],
            ),
          )
      ],
    );
  }

  /// 显示底部集多选操作栏
  _buildButtonsBarAboutEpisodeMulti() {
    if (!animeController.multiSelected.value) return Container();

    return Container(
      alignment: Alignment.bottomCenter,
      child: Card(
        elevation: 8,
        // 圆角
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        // 设置抗锯齿，实现圆角背景
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.fromLTRB(80, 20, 80, 20),
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: IconButton(
                onPressed: () {
                  if (animeController.mapSelected.length ==
                      animeController.episodes.length) {
                    // 全选了，点击则会取消全选
                    animeController.mapSelected.clear();
                  } else {
                    // 其他情况下，全选
                    for (int j = 0; j < animeController.episodes.length; ++j) {
                      animeController.mapSelected[j] = true;
                    }
                  }
                  // 不重绘整个详情页面
                  // setState(() {});
                  // 只重绘集页面
                  animeController.update([animeController.episodeId]);
                },
                icon: const Icon(Icons.select_all_rounded),
                tooltip: "全选",
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () async {
                  await animeController.pickDateForEpisodes(context: context);
                  // 退出多选模式
                  animeController.quitMultiSelectionMode();
                },
                icon: const Icon(Icons.access_time),
                tooltip: "设置观看时间",
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () => animeController.quitMultiSelectionMode(),
                icon: const Icon(Icons.exit_to_app),
                tooltip: "退出多选",
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _showReviewNumberIcon() {
  //   switch (_anime.reviewNumber) {
  //     case 1:
  //       return const Icon(Icons.looks_one_outlined);
  //     case 2:
  //       return const Icon(Icons.looks_two_outlined);
  //     case 3:
  //       return const Icon(Icons.looks_3_outlined);
  //     case 4:
  //       return const Icon(Icons.looks_4_outlined);
  //     case 5:
  //       return const Icon(Icons.looks_5_outlined);
  //     case 6:
  //       return const Icon(Icons.looks_6_outlined);
  //     default:
  //       return const Icon(Icons.error_outline_outlined);
  //   }
  // }
}
