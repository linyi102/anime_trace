import 'package:flutter/material.dart';
import 'package:animetrace/components/common_image.dart';
import 'package:animetrace/animation/fade_animated_switcher.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/controllers/anime_display_controller.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/utils/extensions/color.dart';
import 'package:animetrace/utils/platform.dart';
import 'package:animetrace/values/values.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

// 显示一个完整的动漫封面
// 包括进度、第几次观看、名字
class AnimeGridCover extends StatelessWidget {
  final Anime _anime;
  final bool onlyShowCover; // 动漫详细页只显示封面
  final double coverWidth; // 传入固定宽度，用于水平列表
  final bool showProgress;
  final bool showProgressBar;
  final bool showReviewNumber;
  final bool showName;
  final bool showSeries;
  final bool isSelected;
  final void Function()? onPressed;
  final GestureLongPressCallback? onLongPress;
  final bool loading;

  const AnimeGridCover(
    this._anime, {
    Key? key,
    this.onlyShowCover = false,
    this.showProgress = true,
    this.showProgressBar = false, // 只允许在收藏页显示进度条，聚合搜索页显示会报错
    this.showReviewNumber = true,
    this.showName = true,
    this.showSeries = true,
    this.isSelected = false,
    this.coverWidth = 0,
    this.onPressed,
    this.onLongPress,
    this.loading = false,
  }) : super(key: key);

  double get spacing => 8;
  double get statusSize => 12;
  double get nameSize => PlatformUtil.isMobile ? 13 : 14;

  @override
  Widget build(BuildContext context) {
    final AnimeDisplayController _animeDisplayController = Get.find();

    if (onlyShowCover) return _buildCover(context, false);
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.imgRadius),
      onTap: onPressed,
      onLongPress: onLongPress,
      // 监听是否显示进度、观看次数、原图
      child: Obx(() => Column(
            children: [
              // 封面
              Stack(
                children: [
                  _buildCover(
                      context,
                      _animeDisplayController.showGridAnimeName.value &&
                          _animeDisplayController.showNameInCover.value,
                      reduceMemCache:
                          !_animeDisplayController.showOriCover.value),
                  if (showProgress &&
                      _anime.isCollected() &&
                      _animeDisplayController.showGridAnimeProgress.value)
                    // _anime.animeEpisodeCnt > 0
                    // 不要在集数为0时隐藏，避免搜索时因集数为0，不显示进度导致认为没有收藏
                    _buildEpisodeState(context),
                  _buildHasJoinedSeriesSymbol(context, _anime.hasJoinedSeries),
                  // if (showReviewNumber &&
                  //     _anime.isCollected() &&
                  //     _animeDisplayController.showReviewNumber.value &&
                  //     _anime.reviewNumber > 1)
                  //   _buildReviewNumber(context),
                ],
              ),
              if (_anime.isCollected() &&
                  showProgressBar &&
                  _animeDisplayController.showProgressBar.value)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: LinearProgressIndicator(
                      value: _anime.animeEpisodeCnt == 0
                          ? 0
                          : _anime.checkedEpisodeCnt / _anime.animeEpisodeCnt,
                      backgroundColor: Theme.of(context)
                          .unselectedWidgetColor
                          .withOpacityFactor(0.1),
                    ),
                  ),
                ),
              // 名字
              if (_animeDisplayController.showNameBelowCover && showName)
                _buildNameBelowCover(context),
            ],
          )),
    );
  }

  _buildCover(BuildContext context, bool showNameInCover,
      {bool reduceMemCache = true}) {
    Size mqSize = MediaQuery.of(context).size;

    return Container(
        width: coverWidth == 0 ? null : coverWidth,
        padding: const EdgeInsets.all(3.0),
        child: AspectRatio(
          // 固定宽高比
          aspectRatio: 0.72,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.imgRadius),
            child: Stack(
              children: [
                // loading放在这里是为了保证加载圈处于封面正中央
                FadeAnimatedSwitcher(
                  loadOk: !loading,
                  duration: const Duration(milliseconds: 400),
                  specifiedLoadingWidget: const LoadingWidget(center: true),
                  destWidget: SizedBox(
                    // 确保图片填充
                    width: mqSize.width,
                    height: mqSize.height,
                    child: CommonImage(
                      _anime.getCommonCoverUrl(),
                      reduceMemCache: reduceMemCache,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: mqSize.width,
                    height: mqSize.height,
                    // color: Theme.of(context).primaryColor.withOpacity(0.4),
                    color: Colors.black.withOpacityFactor(0.6),
                    child: const Center(
                        child: Icon(Icons.check, color: Colors.white)),
                  ),
                if (showNameInCover && showName) _buildNameInCover(context)
              ],
            ),
          ),
        ));
  }

  _buildEpisodeState(BuildContext context) {
    return Positioned(
        left: spacing,
        top: spacing,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.stateRadius),
            color: Theme.of(context).colorScheme.primary,
          ),
          child: Text(
            "${_anime.checkedEpisodeCnt}/${_anime.animeEpisodeCnt}",
            style: TextStyle(
                fontSize: statusSize,
                color: Theme.of(context).colorScheme.onPrimary),
          ),
        ));
  }

  _buildHasJoinedSeriesSymbol(BuildContext context, bool hasJoinedSeries) {
    if (!showSeries ||
        !AnimeDisplayController.to.showSeriesFlagInGridStyle.value ||
        !hasJoinedSeries) {
      return const SizedBox();
    }

    return Positioned(
        right: spacing,
        top: spacing,
        child: Container(
          decoration:
              const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
          height: 20,
          width: 20,
          child: const Icon(MingCuteIcons.mgc_book_3_line,
              size: 14, color: Colors.white),
        ));
  }

  buildReviewNumber(BuildContext context) {
    return Positioned(
        right: spacing,
        top: spacing,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.stateRadius),
              color: AppTheme.reviewNumberBg,
            ),
            child: Text(
              "${_anime.reviewNumber}",
              style: TextStyle(
                  fontSize: statusSize, color: AppTheme.reviewNumberFg),
            )));
  }

  _buildNameInCover(BuildContext context) {
    // 封面内部底部文字的背景阴影高度
    double _shadowHeight = 60.0;

    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: _shadowHeight,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                    Colors.transparent,
                    Color.fromRGBO(0, 0, 0, 0.6),
                  ])),
            ),
          ],
        ),
        // 使用Align替换Positioned，可以保证在Stack下自适应父元素宽度
        Container(
          alignment: Alignment.bottomLeft,
          child: Container(
            padding: const EdgeInsets.fromLTRB(5, 0, 10, 5),
            child: _buildNameText(context, nameBelowCover: false),
          ),
        )
      ],
    );
  }

  String _getEllipsisMiddleAnimeName(String name, BoxConstraints constraints) {
    // return name;
    // Log.info(constraints.toString());
    if ((name.length > 3 && name[name.length - 3] == "第") ||
        name.endsWith("OVA")) {
      String testName = name;
      int endIdx = name.length - 3;

      while (!_notOverflow(testName, constraints)) {
        testName =
            "${name.substring(0, endIdx)}...${name.substring(name.length - 3)}";
        endIdx--;
      }
      return testName;
    } else {
      return name;
    }
  }

  // 检测方法参考自https://github.com/leisim/auto_size_text/blob/master/lib/src/auto_size_text.dart
  bool _notOverflow(String name, BoxConstraints constraints) {
    final textPainter = TextPainter(
        text: TextSpan(text: name),
        maxLines: AnimeDisplayController.to.nameMaxLines.value,
        textDirection: TextDirection.ltr);
    textPainter.layout(maxWidth: constraints.maxWidth);
    if (textPainter.didExceedMaxLines) {
      // Log.info("动漫名字溢出：$name");
      return false;
    }
    return true;
  }

  _buildNameBelowCover(BuildContext context) {
    return Container(
        width: coverWidth == 0 ? null : coverWidth,
        padding: const EdgeInsets.only(top: 2, left: 3, right: 3),
        // 保证文字左对齐
        alignment: Alignment.centerLeft,
        child: _buildNameText(context, nameBelowCover: true));
  }

  final bool addStroke = false;
  final bool addShadow = true;
  _buildNameText(BuildContext context, {required bool nameBelowCover}) {
    Color? color;
    if (nameBelowCover) {
      color = Theme.of(context).textTheme.bodyMedium?.color;
    } else {
      color = Colors.white;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        String displayName =
            _getEllipsisMiddleAnimeName(_anime.animeName, constraints);

        // 如果在封面下，则不添加效果
        if (nameBelowCover) {
          return _buildText(displayName, style: TextStyle(color: color));
        }

        // 文字在封面内底部，添加效果使其更加明显
        if (addStroke) {
          return Stack(
            children: [
              // 描边效果
              _buildText(displayName,
                  style: TextStyle(
                      // fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 1
                        ..color = Colors.black)),
              // 正常文字
              _buildText(displayName, style: TextStyle(color: color)),
            ],
          );
        } else if (addShadow) {
          // 阴影文字
          return _buildText(displayName,
              style: TextStyle(
                color: color,
                shadows: const [
                  Shadow(blurRadius: 3, color: Colors.black),
                  // Shadow(blurRadius: 3, color: Colors.black),
                ],
              ));
        } else {
          // 普通文字
          return _buildText(displayName, style: TextStyle(color: color));
        }
      },
    );
  }

  _buildText(String displayName, {TextStyle? style}) {
    return Text(
      displayName,
      maxLines: AnimeDisplayController.to.nameMaxLines.value,
      overflow: TextOverflow.ellipsis,
      style: style?.copyWith(fontWeight: FontWeight.normal, fontSize: nameSize),
    );
  }
}
