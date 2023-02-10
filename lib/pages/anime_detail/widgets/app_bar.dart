import 'dart:ui';

import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_image.dart';
import 'package:flutter_test_future/components/toggle_list_tile.dart';
import 'package:flutter_test_future/pages/anime_detail/controllers/anime_controller.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/pages/anime_cover_detail.dart';
import 'package:flutter_test_future/pages/network/climb/anime_climb_all_website.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:get/get.dart';

class AnimeDetailAppBar extends StatefulWidget {
  const AnimeDetailAppBar(
      {required this.animeController,
      required this.popPage,
      required this.loadData,
      super.key});

  final AnimeController animeController;
  final Function popPage;
  final Function loadData;

  @override
  State<AnimeDetailAppBar> createState() => _AnimeDetailAppBarState();
}

class _AnimeDetailAppBarState extends State<AnimeDetailAppBar> {
  double sigma = SpProfile.getCoverBgSigmaInAnimeDetailPage();

  double coverBgHeightRatio = SpProfile.getCoverBgHeightRatio();

  Color? appBarIconColor = ThemeUtil.isDark
      // ? null
      ? Colors.white
      : null;

  Anime get _anime => widget.animeController.anime;

  @override
  Widget build(BuildContext context) {
    double expandedHeight =
        MediaQuery.of(context).size.height * coverBgHeightRatio;

    return SliverAppBar(
      // 下滑后显示收缩后的AppBar
      pinned: true,
      expandedHeight: expandedHeight,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: SpProfile.getEnableParallaxInAnimeDetailPage()
            ? CollapseMode.parallax // 下滑时添加视差
            : CollapseMode.pin, // 下滑时固定
        background: Stack(
          children: [
            _buildBg(),
            _buildGradient(),
            _buildGestureDetector(),
          ],
        ),
      ),
      leading: IconButton(
          onPressed: () {
            widget.popPage();
          },
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          color: appBarIconColor),
      actions: _generateActions(),
    );
  }

  /// 点击进入封面详情页
  _buildGestureDetector() {
    return GestureDetector(
      onTap: () {
        if (widget.animeController.isCollected) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => AnimeCoverDetail(
                    animeController: widget.animeController,
                  )));
        }
      },
    );
  }

  /// 为底层背景添加渐变效果
  _buildGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: SpProfile.getEnableCoverBgGradient()
                ? [
                    // 最上面添加一点黑色，这样就能看清按钮了
                    Colors.black.withOpacity(0.2),
                    // Colors.white.withOpacity(0.5),
                    // 添加透明色，注意不要用Colors.transparent，否则白色主题会有些黑，过度不自然
                    ThemeUtil.getScaffoldBackgroundColor().withOpacity(0),
                    // 过渡到主体颜色
                    ThemeUtil.getScaffoldBackgroundColor(),
                  ]
                : [
                    Colors.black.withOpacity(0.2),
                    ThemeUtil.getScaffoldBackgroundColor().withOpacity(0),
                    // 最后1个换成透明色，就取消渐变了
                    Colors.transparent
                  ]),
      ),
    );
  }

  /// 底层背景
  _buildBg() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      // 模糊
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
        ),
        child: GetBuilder<AnimeController>(
          id: widget.animeController.coverId,
          init: widget.animeController,
          builder: (controller) {
            return CommonImage(
              widget.animeController.anime.getCommonCoverUrl(),
              showIconWhenUrlIsEmptyOrError: false,
              reduceMemCache: false,
            );
          },
        ),
      ),
    );
  }

  List<Widget> _generateActions() {
    if (!widget.animeController.isCollected) return [];
    return [
      PopupMenuButton(
        icon: Icon(Icons.more_vert, color: appBarIconColor),
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem(
              padding: const EdgeInsets.all(0),
              child: ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text("取消收藏"),
                onTap: () {
                  // 关闭下拉菜单
                  Navigator.pop(context);

                  _dialogDeleteAnime();
                },
              ),
            ),
            PopupMenuItem(
              padding: const EdgeInsets.all(0),
              child: ListTile(
                leading: const Icon(Icons.move_down),
                title: const Text("迁移动漫"),
                onTap: () {
                  // 关闭下拉菜单
                  Navigator.pop(context);

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return AnimeClimbAllWebsite(
                          animeId: _anime.animeId,
                          keyword: _anime.animeName,
                        );
                      },
                    ),
                  ).then((value) {
                    // 从数据库中获取迁移后的动漫
                    widget.loadData();
                  });
                },
              ),
            ),
            PopupMenuItem(
              padding: const EdgeInsets.all(0),
              child: ListTile(
                leading: const Icon(Entypo.layout),
                title: const Text("外观设置"),
                onTap: () {
                  // 关闭下拉菜单
                  Navigator.pop(context);
                  _showLayoutBottomSheet();
                },
              ),
            )
          ];
        },
      ),
    ];
  }

  _dialogDeleteAnime() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("提示"),
            content: const Text("这将会删除所有相关记录，\n确认取消收藏吗？"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("取消")),
              ElevatedButton(
                  onPressed: () {
                    SqliteUtil.deleteAnimeByAnimeId(_anime.animeId);
                    // 关闭当前对话框
                    Navigator.of(context).pop();
                    // 退出当前页
                    // _popAnimeDetailPage();
                    // 不用退出
                    widget.animeController.deleteAnime();
                  },
                  child: const Text("确认")),
            ],
          );
        });
  }

  void _popAnimeDetailPage() {
    // 置为0，用于在收藏页得知已取消收藏
    _anime.animeId = 0;
    // 退出动漫详细页面
    Navigator.of(context).pop(_anime);
  }

  // 弹出底部弹出菜单，用于外观设置
  _showLayoutBottomSheet() {
    showFlexibleBottomSheet(
      duration: const Duration(milliseconds: 200),
      minHeight: 0,
      initHeight: 0.3,
      maxHeight: 1,
      context: context,
      isExpand: true,
      builder: (
        BuildContext context,
        ScrollController scrollController,
        double bottomSheetOffset,
      ) =>
          StatefulBuilder(
              builder: (context, setBottomSheetState) => Scaffold(
                    body: ListView(
                      children: [
                        ToggleListTile(
                          title: const Text("背景模糊"),
                          toggleOn: sigma > 0, // >0说明开启了模糊
                          onTap: () {
                            sigma = sigma > 0 ? 0.0 : 10.0;
                            SpProfile.setCoverBgSigmaInAnimeDetailPage(sigma);
                            // 重新渲染开关
                            setBottomSheetState(() {});
                            // 重新渲染背景
                            setState(() {});
                          },
                        ),
                        ToggleListTile(
                          title: const Text("背景渐变"),
                          toggleOn: SpProfile.getEnableCoverBgGradient(),
                          onTap: () {
                            SpProfile.turnEnableCoverBgGradient();
                            setBottomSheetState(() {});
                            setState(() {});
                          },
                        ),
                        ToggleListTile(
                          title: const Text("显示简介"),
                          toggleOn: widget
                              .animeController.showDescInAnimeDetailPage.value,
                          onTap: () {
                            widget.animeController
                                .turnShowDescInAnimeDetailPage();
                            setBottomSheetState(() {});
                            // 不需要重新渲染AppBar
                            // setState(() {});
                            // 而是通知控制器重绘
                            widget.animeController.updateAnimeInfo();
                          },
                        ),
                        ToggleListTile(
                          title: const Text("滚动视差"),
                          toggleOn:
                              SpProfile.getEnableParallaxInAnimeDetailPage(),
                          onTap: () {
                            SpProfile.turnEnableParallaxInAnimeDetailPage();
                            setBottomSheetState(() {});
                            setState(() {});
                          },
                        ),
                        // 调节封面背景高度
                        _buildSetCoverHeightTile(setBottomSheetState)
                      ],
                    ),
                  )),
    );
  }

  _buildSetCoverHeightTile(StateSetter setBottomSheetState) {
    return ListTile(
        title: const Text("背景高度"),
        trailing: SizedBox(
          width: 200,
          child: Stack(
            children: [
              SizedBox(
                width: 190,
                child: Slider(
                  min: 0.1,
                  max: 1,
                  // 显示数字(只有指定divisions后才会显示)
                  // label:
                  // "${coverBgHeightRatio.toPrecision(2)}",
                  divisions: 30,
                  // 分成30个刻度
                  value: coverBgHeightRatio,
                  onChanged: (value) {
                    Log.info("拖动中，value=$value");
                    coverBgHeightRatio = value;

                    setBottomSheetState(() {});
                    setState(() {});
                  },
                  onChangeEnd: (value) {
                    // 拖动结束后
                    Log.info("拖动结束，value=$value");
                    SpProfile.setCoverBgHeightRatio(value);
                  },
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text("${coverBgHeightRatio.toPrecision(2)}",
                    textScaleFactor: 0.8),
              )
            ],
          ),
        ));
  }
}
