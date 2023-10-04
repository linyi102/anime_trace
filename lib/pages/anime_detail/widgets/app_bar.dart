import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/anime_rating_bar.dart';
import 'package:flutter_test_future/components/common_image.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/pages/anime_detail/controllers/anime_controller.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/pages/anime_cover_detail.dart';
import 'package:flutter_test_future/pages/anime_detail/pages/ui_setting.dart';
import 'package:flutter_test_future/pages/network/climb/anime_climb_all_website.dart';
import 'package:flutter_test_future/pages/settings/image_wall/note_image_wall.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class AnimeDetailAppBar extends StatefulWidget {
  const AnimeDetailAppBar(
      {required this.animeController, required this.popPage, super.key});

  final AnimeController animeController;
  final Function popPage;

  @override
  State<AnimeDetailAppBar> createState() => _AnimeDetailAppBarState();
}

class _AnimeDetailAppBarState extends State<AnimeDetailAppBar> {
  double sigma = SpProfile.getCoverBgSigmaInAnimeDetailPage();

  double coverBgHeightRatio = SpProfile.getCoverBgHeightRatio();

  bool transparentBottomSheet = false;

  Anime get _anime => widget.animeController.anime;

  @override
  Widget build(BuildContext context) {
    double expandedHeight =
        MediaQuery.of(context).size.height * coverBgHeightRatio;

    return GetBuilder<AnimeController>(
      id: widget.animeController.appbarId,
      tag: widget.animeController.tag,
      init: widget.animeController,
      initState: (_) {},
      builder: (_) {
        Log.info("build ${widget.animeController.appbarId}");

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
                // _buildCoverAndInfo(),
                _buildGestureDetector(),
              ],
            ),
          ),
          leading: _buildAppBarIconButton(
            context: context,
            onTap: () => widget.popPage(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
          actions: _generateActions(),
        );
      },
    );
  }

  _buildAppBarIconButton({
    required BuildContext context,
    required Widget icon,
    void Function()? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.all(6.0),
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: onTap,
        child: Center(
          child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: icon),
        ),
      ),
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
    var scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: SpProfile.getEnableCoverBgGradient()
                ? [
                    // Colors.black.withOpacity(0),
                    // 最上面添加一点黑色，这样就能看清按钮了
                    Colors.black.withOpacity(0.2),
                    // Colors.white.withOpacity(0.2),
                    // 添加透明色，注意不要用Colors.transparent，否则白色主题会有些黑，过度不自然
                    scaffoldBgColor.withOpacity(0),
                    // 过渡到主体颜色
                    scaffoldBgColor,
                  ]
                : [
                    Colors.black.withOpacity(0.2),
                    scaffoldBgColor.withOpacity(0),
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
          tag: widget.animeController.tag,
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
      _buildAppBarIconButton(
        context: context,
        onTap: () => _showLayoutBottomSheet(),
        // icon: const Icon(Icons.filter_list),
        icon: const Icon(
          // Icons.filter_list,
          Icons.layers_outlined,
          // MingCuteIcons.mgc_layout_line,
        ),
      ),
      _buildAppBarIconButton(
          context: context,
          icon: Center(
            child: PopupMenuButton(
              padding: EdgeInsets.zero,
              position: PopupMenuPosition.under,
              icon: const Icon(
                // MingCuteIcons.mgc_more_2_line,
                Icons.more_vert,
              ),
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    padding: const EdgeInsets.all(0),
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline),
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
                      leading: const Icon(MingCuteIcons.mgc_transfer_line),
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
                          widget.animeController.loadAnime(_anime);
                          // TODO 集数也可能会变化，因此也需要重绘集页面，但会导致前面的集丢失了笔记
                          // widget.animeController.loadEpisode();
                        });
                      },
                    ),
                  ),
                  PopupMenuItem(
                    padding: const EdgeInsets.all(0),
                    child: ListTile(
                      leading: const Icon(Icons.panorama_horizontal_rounded),
                      title: const Text("照片墙"),
                      onTap: () {
                        // 关闭下拉菜单
                        Navigator.pop(context);

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteImageWallPage(
                                animeId: _anime.animeId,
                              ),
                            ));
                      },
                    ),
                  ),
                ];
              },
            ),
          ))
    ];
  }

  _dialogDeleteAnime() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("确定取消收藏吗？"),
            content: const Text("这将会删除所有相关记录！"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("取消")),
              TextButton(
                  onPressed: () {
                    AnimeDao.deleteAnimeByAnimeId(_anime.animeId);
                    // 关闭当前对话框
                    Navigator.of(context).pop();
                    // 退出当前页，没必要不退出，而且搜索源详情页的详细列表进入后取消收藏后返回没有删除
                    _anime.animeId = 0;
                    widget.popPage();
                    // 不用退出
                    // widget.animeController.resetAnime();
                  },
                  child: Text("确定",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
            ],
          );
        });
  }

  // 弹出底部弹出菜单，用于外观设置
  _showLayoutBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setBottomSheetState) => AnimeDetailUISettingPage(
          sortPage: widget.animeController.buildSortPage(),
          uiPage: _buildUISettingPage(setBottomSheetState),
          transparent: transparentBottomSheet,
        ),
      ),
    );
  }

  _buildUISettingPage(StateSetter setBottomSheetState) {
    return ListView(
      children: [
        SwitchListTile(
          title: const Text("背景模糊"),
          value: sigma > 0, // >0说明开启了模糊
          onChanged: (bool value) {
            sigma = sigma > 0 ? 0.0 : 10.0;
            SpProfile.setCoverBgSigmaInAnimeDetailPage(sigma);
            // 重新渲染开关
            setBottomSheetState(() {});
            // 重新渲染背景
            setState(() {});
          },
        ),
        SwitchListTile(
          title: const Text("背景渐变"),
          value: SpProfile.getEnableCoverBgGradient(),
          onChanged: (bool value) {
            SpProfile.turnEnableCoverBgGradient();
            setBottomSheetState(() {});
            setState(() {});
          },
        ),
        SwitchListTile(
          title: const Text("显示简介"),
          value: widget.animeController.showDescInAnimeDetailPage.value,
          onChanged: (bool value) {
            widget.animeController.turnShowDescInAnimeDetailPage();
            setBottomSheetState(() {});
            // 不需要重新渲染AppBar
            // setState(() {});
            // 而是通知控制器重绘
            widget.animeController.updateAnimeInfo();
          },
        ),
        SwitchListTile(
          title: const Text("滚动视差"),
          value: SpProfile.getEnableParallaxInAnimeDetailPage(),
          onChanged: (bool value) {
            SpProfile.turnEnableParallaxInAnimeDetailPage();
            setBottomSheetState(() {});
            setState(() {});
          },
        ),
        // 调节封面背景高度
        _buildSetCoverHeightTile(setBottomSheetState)
      ],
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
                  // 分成n个刻度
                  divisions: 90,
                  value: coverBgHeightRatio,
                  onChangeStart: (value) {
                    transparentBottomSheet = true;
                    setBottomSheetState(() {});
                    setState(() {});
                  },
                  onChanged: (value) {
                    Log.info("拖动中，value=$value");

                    coverBgHeightRatio = value;
                    setBottomSheetState(() {});
                    setState(() {});
                  },
                  onChangeEnd: (value) {
                    // 拖动结束后，保存
                    Log.info("拖动结束，value=$value");
                    SpProfile.setCoverBgHeightRatio(value);

                    transparentBottomSheet = false;
                    setBottomSheetState(() {});
                    setState(() {});
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

  _buildCoverAndInfo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _showAnimeRow(),
        ],
      ),
    );
  }

  _buildRatingStars() {
    return AnimeRatingBar(
        enableRate: widget.animeController.isCollected, // 未收藏时不能评分
        rate: _anime.rate,
        iconSize: 15,
        onRatingUpdate: (v) {
          Log.info("评价分数：$v");
          _anime.rate = v.toInt();
          AnimeDao.updateAnimeRate(_anime.animeId, _anime.rate);
        });
  }

  _showAnimeRow() {
    return Row(
      children: [
        // 动漫封面
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: MaterialButton(
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => AnimeCoverDetail(
                                animeController: widget.animeController,
                              )));
                    },
                    child: AnimeGridCover(widget.animeController.anime,
                        onlyShowCover: true),
                  ),
                ),
              ),
            ),
          ],
        ),
        // 动漫信息
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(left: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _showAnimeName(widget.animeController.anime.animeName),
                _showNameAnother(widget.animeController.anime.nameAnother),
                _showAnimeInfo(
                    widget.animeController.anime.getAnimeInfoFirstLine()),
                _showAnimeInfo(
                    widget.animeController.anime.getAnimeInfoSecondLine()),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.fromLTRB(0, 5, 15, 5),
                  child: _buildRatingStars(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _showAnimeName(animeName) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(0, 5, 15, 5),
      child: SelectableText(
        animeName,
        // maxLines: 1,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  _showNameAnother(String nameAnother) {
    return nameAnother.isEmpty
        ? Container()
        : Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.fromLTRB(0, 5, 35, 0),
            child: SelectableText(
              nameAnother,
              style: const TextStyle(height: 1.1),
              maxLines: 1,
            ),
          );
  }

  _showAnimeInfo(String animeInfo) {
    return animeInfo.isEmpty
        ? Container()
        : Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.fromLTRB(0, 5, 15, 0),
            child: SelectableText(
              animeInfo,
              style: const TextStyle(height: 1.1),
              maxLines: 1,
            ),
          );
  }
}
