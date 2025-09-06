import 'package:animetrace/animation/fade_animated_switcher.dart';
import 'package:animetrace/components/common_image.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/utils/extensions/color.dart';
import 'package:animetrace/values/theme.dart';
import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

enum Placement {
  none,
  bottomInCover,
  bottomOutCover,
  topLeft,
  topRight,
}

extension PlacementExtension on Placement {
  String get label {
    return switch (this) {
      Placement.none => '隐藏',
      Placement.bottomInCover => '封面内底部',
      Placement.bottomOutCover => '封面下方',
      Placement.topLeft => '左上角',
      Placement.topRight => '右上角',
    };
  }
}

class AnimeCoverStyle {
  final Placement namePlacement;
  final Placement progressLinearPlacement;
  final Placement progressNumberPlacement;
  final Placement seriesPlacement;
  final int maxNameLines;

  const AnimeCoverStyle({
    this.namePlacement = Placement.bottomOutCover,
    this.progressLinearPlacement = Placement.none,
    this.progressNumberPlacement = Placement.topLeft,
    this.seriesPlacement = Placement.topRight,
    this.maxNameLines = 1,
  });

  factory AnimeCoverStyle.none() {
    return const AnimeCoverStyle(
      namePlacement: Placement.none,
      progressLinearPlacement: Placement.none,
      progressNumberPlacement: Placement.none,
      seriesPlacement: Placement.none,
    );
  }

  Map<String, dynamic> toJson() => {
        'namePlacement': namePlacement.name,
        'progressLinearPlacement': progressLinearPlacement.name,
        'progressNumberPlacement': progressNumberPlacement.name,
        'seriesPlacement': seriesPlacement.name,
        'maxNameLines': maxNameLines,
      };

  factory AnimeCoverStyle.fromJson(Map<String, dynamic> json) {
    return AnimeCoverStyle(
      namePlacement: Placement.values.firstWhere(
        (e) => e.name == json['namePlacement'],
        orElse: () => Placement.bottomOutCover,
      ),
      progressLinearPlacement: Placement.values.firstWhere(
        (e) => e.name == json['progressLinearPlacement'],
        orElse: () => Placement.bottomOutCover,
      ),
      progressNumberPlacement: Placement.values.firstWhere(
        (e) => e.name == json['progressNumberPlacement'],
        orElse: () => Placement.topLeft,
      ),
      seriesPlacement: Placement.values.firstWhere(
        (e) => e.name == json['seriesPlacement'],
        orElse: () => Placement.topRight,
      ),
      maxNameLines: json['maxNameLines'] ?? 1,
    );
  }

  AnimeCoverStyle copyWith({
    Placement? namePlacement,
    Placement? progressLinearPlacement,
    Placement? progressNumberPlacement,
    Placement? seriesPlacement,
    int? maxNameLines,
  }) {
    return AnimeCoverStyle(
      namePlacement: namePlacement ?? this.namePlacement,
      progressLinearPlacement:
          progressLinearPlacement ?? this.progressLinearPlacement,
      progressNumberPlacement:
          progressNumberPlacement ?? this.progressNumberPlacement,
      seriesPlacement: seriesPlacement ?? this.seriesPlacement,
      maxNameLines: maxNameLines ?? this.maxNameLines,
    );
  }
}

class CustomAnimeCover extends StatelessWidget {
  final Anime anime;
  final AnimeCoverStyle style;
  final double? width;
  final EdgeInsets? margin;
  final bool selected;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final bool showLoading;

  const CustomAnimeCover({
    super.key,
    required this.anime,
    this.style = const AnimeCoverStyle(),
    this.width,
    this.margin,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.showLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final collected = anime.isCollected();
    final numberProgressWidget = collected
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.stateRadius),
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              '${anime.checkedEpisodeCnt}/${anime.animeEpisodeCnt}',
              style: TextStyle(
                  fontSize: 12, color: Theme.of(context).colorScheme.onPrimary),
            ),
          )
        : null;
    final seriesWidget = collected && anime.hasJoinedSeries
        ? Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primaryFixed),
            height: 20,
            width: 20,
            child: Icon(MingCuteIcons.mgc_book_3_line,
                size: 14, color: Theme.of(context).colorScheme.onPrimaryFixed),
          )
        : null;

    List<Widget> topLeftStatusWidgets = [];
    if (collected &&
        numberProgressWidget != null &&
        style.progressNumberPlacement == Placement.topLeft) {
      topLeftStatusWidgets.add(numberProgressWidget);
    }
    if (seriesWidget != null && style.seriesPlacement == Placement.topLeft) {
      topLeftStatusWidgets.add(seriesWidget);
    }

    List<Widget> topRightStatusWidgets = [];
    if (seriesWidget != null && style.seriesPlacement == Placement.topRight) {
      topRightStatusWidgets.add(seriesWidget);
    }
    if (numberProgressWidget != null &&
        style.progressNumberPlacement == Placement.topRight) {
      topRightStatusWidgets.add(numberProgressWidget);
    }

    final borderRadius = BorderRadius.circular(AppTheme.imgRadius);

    return Container(
      width: width,
      margin: margin ?? const EdgeInsets.all(4),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: borderRadius,
              child: AspectRatio(
                aspectRatio: 0.72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FadeAnimatedSwitcher(
                      loadOk: !showLoading,
                      duration: const Duration(milliseconds: 400),
                      specifiedLoadingWidget: const LoadingWidget(center: true),
                      destWidget: CommonImage(anime.getCommonCoverUrl()),
                      // 保证图片填充
                      stackFit: StackFit.expand,
                    ),
                    if (selected)
                      Material(
                        color: Colors.black.withOpacityFactor(0.6),
                        child: const Center(
                            child: Icon(Icons.check, color: Colors.white)),
                      ),
                    // 左上角组件
                    if (topLeftStatusWidgets.isNotEmpty)
                      Positioned(
                        left: 0,
                        top: 8,
                        child: Row(
                            children: topLeftStatusWidgets
                                .map((e) => Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: e))
                                .toList()),
                      ),
                    // 右上角组件
                    if (topRightStatusWidgets.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 8,
                        child: Row(
                            children: topRightStatusWidgets
                                .map((e) => Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: e))
                                .toList()),
                      ),
                    // 封面内底部组件
                    if (style.namePlacement == Placement.bottomInCover ||
                        style.progressLinearPlacement ==
                            Placement.bottomInCover)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(top: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (style.namePlacement ==
                                    Placement.bottomInCover)
                                  _buildName(enableShadow: true),
                                if (style.progressLinearPlacement ==
                                    Placement.bottomInCover)
                                  _buildLinearProgress(),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // 封面下方组件
            if (style.namePlacement == Placement.bottomOutCover ||
                style.progressLinearPlacement == Placement.bottomOutCover)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (style.progressLinearPlacement ==
                        Placement.bottomOutCover)
                      _buildLinearProgress(),
                    if (style.namePlacement == Placement.bottomOutCover)
                      _buildName(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Padding _buildName({bool enableShadow = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _AnimeName(
        anime.animeName,
        maxLines: style.maxNameLines,
        enableShadow: enableShadow,
        color: enableShadow ? Colors.white : null,
      ),
    );
  }

  Widget _buildLinearProgress() {
    return !anime.isCollected()
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: anime.animeEpisodeCnt == 0
                    ? 0
                    : anime.checkedEpisodeCnt / anime.animeEpisodeCnt,
              ),
            ),
          );
  }
}

class _AnimeName extends StatelessWidget {
  const _AnimeName(
    this.name, {
    this.color,
    this.maxLines = 1,
    this.enableShadow = false,
  });
  final String name;
  final Color? color;
  final int maxLines;
  final bool enableShadow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle = TextStyle(
          color: color,
          shadows: enableShadow
              ? const [Shadow(blurRadius: 3, color: Colors.black)]
              : null,
        );
        final displayName = _getEllipsMiddleName(
            name: name, textStyle: textStyle, constraints: constraints);

        return Text(
          displayName,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        );
      },
    );
  }

  String _getEllipsMiddleName({
    required String name,
    required TextStyle textStyle,
    required BoxConstraints constraints,
  }) {
    bool isOverflow(String name) {
      final textPainter = TextPainter(
          text: TextSpan(text: name, style: textStyle),
          maxLines: maxLines,
          textDirection: TextDirection.ltr);
      // 可能有微小误差，因此缩小测试的最大宽度
      textPainter.layout(maxWidth: constraints.maxWidth - 4);
      return textPainter.didExceedMaxLines;
    }

    if ((name.length > 3 && name[name.length - 3] == '第') ||
        name.endsWith('OVA')) {
      String tmpName = name;
      int endIdx = name.length - 3;

      final textPainter = TextPainter(
        text: TextSpan(text: name),
        maxLines: maxLines,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: constraints.maxWidth);

      while (isOverflow(tmpName) && endIdx > 0) {
        tmpName =
            '${name.substring(0, endIdx)}...${name.substring(name.length - 3)}';
        endIdx--;
      }
      return tmpName;
    } else {
      return name;
    }
  }
}
