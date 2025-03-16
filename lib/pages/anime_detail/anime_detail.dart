import 'dart:async';

import 'package:flutter/material.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/global.dart';

import 'package:animetrace/pages/anime_detail/controllers/anime_controller.dart';
import 'package:animetrace/controllers/labels_controller.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/pages/anime_detail/widgets/app_bar.dart';
import 'package:animetrace/pages/anime_detail/widgets/episode.dart';
import 'package:animetrace/pages/anime_detail/widgets/info.dart';
import 'package:animetrace/pages/viewer/video/view_with_load_url.dart';
import 'package:animetrace/utils/climb/climb_anime_util.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/platform.dart';
import 'package:animetrace/utils/time_util.dart';
import 'package:animetrace/widgets/floating_bottom_actions.dart';
import 'package:animetrace/widgets/multi_platform.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

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
  bool get enableSplitScreenInLandscape => false;

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
      child: MultiPlatform(
        mobile: _buildMobileDetailPage(),
        desktop: _buildDesktopDetailPage(),
      ),
    );
  }

  _buildDesktopDetailPage() {
    double rightWidth = 340;

    return GetBuilder(
      init: animeController,
      builder: (_) {
        if (animeController.curPlayEpisode == null) {
          return _buildDetailScreen();
        }

        return Row(
          children: [
            Expanded(child: _buildVideoScreen()),
            Offstage(
              offstage: animeController.rightDetailScreenIsFolded,
              child: SizedBox(
                width: rightWidth,
                child: _buildDetailScreen(),
              ),
            ),
          ],
        );
      },
    );
  }

  _buildVideoScreen() {
    return Stack(
      children: [
        VideoPlayerWithLoadUrlPage(
          key: Key('${animeController.curPlayEpisode?.number}'),
          leading: PlatformUtil.isDesktop
              ? IconButton(
                  onPressed: () => animeController.closeEpisodePlayPage(),
                  icon: const Icon(Icons.close, color: Colors.white))
              : null,
          loadUrl: () async {
            String url = await ClimbAnimeUtil.getVideoUrl(
                animeController.anime.animeUrl,
                animeController.curPlayEpisode!.number);
            return url;
          },
          title:
              '${animeController.anime.animeName} - ${animeController.curPlayEpisode?.caption}',
          whenDesktopToggleFullScreen: (isFullScreen) {
            if (PlatformUtil.isDesktop) {
              isFullScreen
                  ? animeController.foldRightDetailScreen()
                  : animeController.unfoldRightDetailScreen();
            }
          },
        ),
        _FoldDetailScreenButton(animeController: animeController)
      ],
    );
  }

  Scaffold _buildMobileDetailPage() => _buildDetailScreen();

  // 避免打开/关闭左侧播放区域后重绘右侧详情区域
  final detailScreenKey = GlobalKey();

  Scaffold _buildDetailScreen() {
    return Scaffold(
      key: detailScreenKey,
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
                if (enableSplitScreenInLandscape &&
                    Global.isLandscape(context)) {
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
    return FloatingBottomActions(
      display: animeController.multiSelected.value,
      children: [
        IconButton(
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
        IconButton(
          onPressed: () async {
            await animeController.pickDateForEpisodes(context: context);
            animeController.quitMultiSelectionMode();
          },
          icon: const Icon(MingCuteIcons.mgc_calendar_time_add_line),
          tooltip: "设置观看时间",
        ),
        IconButton(
          onPressed: () async {
            await animeController.pickDateForEpisodes(
                context: context, dateTime: TimeUtil.unRecordedDateTime);
            animeController.quitMultiSelectionMode();
          },
          icon: const Icon(MingCuteIcons.mgc_check_circle_line),
          tooltip: "仅标记完成",
        ),
        IconButton(
          onPressed: () => animeController.quitMultiSelectionMode(),
          icon: const Icon(Icons.exit_to_app),
          tooltip: "退出多选",
        ),
      ],
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

class _FoldDetailScreenButton extends StatefulWidget {
  const _FoldDetailScreenButton({
    required this.animeController,
  });

  final AnimeController animeController;

  @override
  State<_FoldDetailScreenButton> createState() =>
      _FoldDetailScreenButtonState();
}

class _FoldDetailScreenButtonState extends State<_FoldDetailScreenButton> {
  bool show = false;
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      hitTestBehavior: HitTestBehavior.translucent,
      onEnter: (_) => _showButton(),
      onExit: (_) => setState(() => show = false),
      onHover: (_) {
        if (show) {
          _resetTimer();
          return;
        }
        _showButton();
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: show ? 1 : 0,
        child: Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: () => widget.animeController.foldOrUnfoldRightDetailScreen(),
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(8))),
              height: 50,
              width: 24,
              child: Center(
                child: Icon(
                  widget.animeController.rightDetailScreenIsFolded
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _resetTimer() {
    timer?.cancel();
    timer = Timer(const Duration(seconds: 3), () {
      if (mounted && show) {
        setState(() => show = false);
      }
    });
  }

  _showButton() {
    setState(() => show = true);
    _resetTimer();
  }
}
