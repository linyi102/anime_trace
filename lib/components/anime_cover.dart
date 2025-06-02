import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import 'package:animetrace/animation/fade_animated_switcher.dart';
import 'package:animetrace/components/common_image.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/controllers/anime_display_controller.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/utils/extensions/color.dart';
import 'package:animetrace/utils/platform.dart';
import 'package:animetrace/values/theme.dart';

class AnimeCoverConfig {
  bool showName;
  _NameAlignment nameAlignment;
  int nameMaxLines;

  bool showSeries;
  Alignment seriesAlignment;

  bool showProgress;
  Alignment progressAlignment;

  bool showReviewNumber;
  Alignment reviewNumberAlignment;

  bool showProgressBar;

  AnimeCoverConfig({
    this.showName = true,
    this.nameAlignment = _NameAlignment.bottomOutCover,
    this.nameMaxLines = 2,
    this.showSeries = true,
    this.seriesAlignment = Alignment.topRight,
    this.showReviewNumber = true,
    this.reviewNumberAlignment = Alignment.topRight,
    this.showProgress = true,
    this.progressAlignment = Alignment.topLeft,
    this.showProgressBar = false,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'showName': showName,
      'nameAlignment': nameAlignment.value,
      'nameMaxLines': nameMaxLines,
      'showSeries': showSeries,
      'seriesAlignment': seriesAlignment.value,
      'showProgress': showProgress,
      'progressAlignment': progressAlignment.value,
      'showReviewNumber': showReviewNumber,
      'reviewNumberAlignment': reviewNumberAlignment.value,
      'showProgressBar': showProgressBar,
    };
  }

  factory AnimeCoverConfig.fromMap(Map<String, dynamic> map) {
    return AnimeCoverConfig(
      showName: map['showName'] as bool,
      nameAlignment: _NameAlignment.fromValue(map['nameAlignment']),
      nameMaxLines: map['nameMaxLines'] as int,
      showSeries: map['showSeries'] as bool,
      seriesAlignment: _alignmentFromValue(map['seriesAlignment']),
      showProgress: map['showProgress'] as bool,
      progressAlignment: _alignmentFromValue(map['progressAlignment']),
      showReviewNumber: map['showReviewNumber'] as bool,
      reviewNumberAlignment: _alignmentFromValue(map['reviewNumberAlignment']),
      showProgressBar: map['showProgressBar'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory AnimeCoverConfig.fromJson(String source) =>
      AnimeCoverConfig.fromMap(json.decode(source) as Map<String, dynamic>);
}

enum _NameAlignment {
  bottomInCover(1),
  bottomOutCover(2),
  ;

  final int value;
  const _NameAlignment(this.value);

  static _NameAlignment fromValue(dynamic value) {
    return _NameAlignment.values.firstWhereOrNull((e) => e.value == value) ??
        _NameAlignment.bottomInCover;
  }
}

extension _AlignmentHelper on Alignment {
  int get value {
    switch (this) {
      case Alignment.topLeft:
        return 1;
      case Alignment.topRight:
        return 2;
      case Alignment.bottomLeft:
        return 3;
      case Alignment.bottomRight:
        return 4;
    }
    return 1;
  }
}

Alignment _alignmentFromValue(dynamic value) {
  switch (value) {
    case 1:
      return Alignment.topLeft;
    case 2:
      return Alignment.topRight;
    case 3:
      return Alignment.bottomLeft;
    case 4:
      return Alignment.bottomRight;
  }
  return Alignment.topLeft;
}

class AnimeCover extends StatelessWidget {
  AnimeCover({
    super.key,
    required this.anime,
    this.coverWidth,
    this.isSelected = false,
    this.loading = false,
    this.onPressed,
    this.onLongPress,
  });
  final Anime anime;
  final double? coverWidth;
  final bool isSelected;
  final bool loading;
  final GestureTapCallback? onPressed;
  final GestureLongPressCallback? onLongPress;

  AnimeCoverConfig get config => AnimeCoverConfig();
  late final AnimeDisplayController animeDisplayController = Get.find();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.imgRadius),
      onTap: onPressed,
      onLongPress: onLongPress,
      // 监听是否显示进度、观看次数、原图
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 封面
          Stack(
            children: [
              _buildCover(context),
              Positioned(
                left: 8,
                top: 8,
                child: _buildStates(context, Alignment.topLeft),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: _buildStates(context, Alignment.topRight),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: _buildStates(context, Alignment.bottomLeft),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: _buildStates(context, Alignment.bottomRight),
              ),
            ],
          ),
          if (anime.isCollected() && config.showProgressBar)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: LinearProgressIndicator(
                  value: anime.animeEpisodeCnt == 0
                      ? 0
                      : anime.checkedEpisodeCnt / anime.animeEpisodeCnt,
                  backgroundColor: Theme.of(context)
                      .unselectedWidgetColor
                      .withOpacityFactor(0.1),
                ),
              ),
            ),
          // 名字
          if (config.showName &&
              config.nameAlignment == _NameAlignment.bottomOutCover)
            _buildNameText(context),
        ],
      ),
    );
  }

  Widget _buildStates(BuildContext context, Alignment alignment) {
    if (!anime.isCollected()) return const SizedBox();

    final states = [
      if (config.showProgress && config.progressAlignment == alignment)
        _buildEpisodeState(context),
      if (config.showReviewNumber && config.reviewNumberAlignment == alignment)
        _buildReviewNumber(context),
      if (config.showSeries &&
          anime.hasJoinedSeries &&
          config.seriesAlignment == alignment)
        _buildHasJoinedSeriesSymbol(),
    ];
    return Wrap(
      spacing: 4,
      // 左侧时，展示集、回顾、系列，右侧时展示系列、回顾、集
      children: alignment.x == -1 ? states : states.reversed.toList(),
    );
  }

  Widget _buildCover(BuildContext context) {
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
                      anime.getCommonCoverUrl(),
                      reduceMemCache:
                          !animeDisplayController.showOriCover.value,
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
                if (config.showName &&
                    config.nameAlignment == _NameAlignment.bottomInCover)
                  _buildNameText(context)
              ],
            ),
          ),
        ));
  }

  Widget _buildEpisodeState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.stateRadius),
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Text(
        "${anime.checkedEpisodeCnt}/${anime.animeEpisodeCnt}",
        style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onPrimary,
            height: 1.4),
      ),
    );
  }

  Widget _buildReviewNumber(BuildContext context) {
    if (anime.reviewNumber <= 1) return const SizedBox();
    return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.reviewNumberBg,
        ),
        height: 20,
        width: 20,
        child: Center(
          child: Text(
            "${anime.reviewNumber}",
            style: TextStyle(
                fontSize: 12, color: AppTheme.reviewNumberFg, height: 1),
          ),
        ));
  }

  Widget _buildHasJoinedSeriesSymbol() {
    return Container(
      decoration:
          const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
      height: 20,
      width: 20,
      child: const Icon(MingCuteIcons.mgc_book_3_line,
          size: 14, color: Colors.white),
    );
  }

  Widget _buildNameText(BuildContext context) {
    // 检测方法参考自https://github.com/leisim/auto_size_text/blob/master/lib/src/auto_size_text.dart
    bool _notOverflow(String name, BoxConstraints constraints) {
      final textPainter = TextPainter(
          text: TextSpan(text: name),
          maxLines: config.nameMaxLines,
          textDirection: TextDirection.ltr);
      textPainter.layout(maxWidth: constraints.maxWidth);
      if (textPainter.didExceedMaxLines) {
        // Log.info("动漫名字溢出：$name");
        return false;
      }
      return true;
    }

    String _getEllipsisMiddleAnimeName(
        String name, BoxConstraints constraints) {
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

    Widget _buildText({TextStyle? style}) {
      return LayoutBuilder(builder: (context, constraints) {
        String displayName =
            _getEllipsisMiddleAnimeName(anime.animeName, constraints);
        return Text(
          displayName,
          maxLines: config.nameMaxLines,
          overflow: TextOverflow.ellipsis,
          style: style?.copyWith(
              fontWeight: FontWeight.normal,
              fontSize: PlatformUtil.isMobile ? 13 : 14),
        );
      });
    }

    switch (config.nameAlignment) {
      case _NameAlignment.bottomOutCover:
        return Container(
          width: coverWidth == 0 ? null : coverWidth,
          padding: const EdgeInsets.only(top: 2, left: 3, right: 3),
          // 保证文字左对齐
          alignment: Alignment.centerLeft,
          child: _buildText(
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
        );
      case _NameAlignment.bottomInCover:
        return Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 60,
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
                child: _buildText(
                    style: const TextStyle(
                  color: Colors.white,
                  shadows: [
                    Shadow(blurRadius: 3, color: Colors.black),
                  ],
                )),
              ),
            )
          ],
        );
    }
  }
}
