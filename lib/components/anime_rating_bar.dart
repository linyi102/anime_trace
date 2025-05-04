import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:animetrace/utils/extensions/color.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class AnimeRatingBar extends StatelessWidget {
  const AnimeRatingBar(
      {required this.rate,
      this.onRatingUpdate,
      this.enableRate = true,
      this.iconSize,
      this.spacing,
      Key? key})
      : super(key: key);
  final int rate;
  final double? iconSize;
  final double? spacing;
  final bool enableRate;
  final void Function(double)? onRatingUpdate;

  double get _rate => rate / 2;

  @override
  Widget build(BuildContext context) {
    return enableRate
        ? RatingBar.builder(
            // 拖拽星级时会发出绿色光，所以屏蔽掉
            glow: false,
            allowHalfRating: true,
            initialRating: _rate,
            itemSize: iconSize ?? 20,
            itemPadding: EdgeInsets.only(right: spacing ?? 5),
            unratedColor: Colors.grey.withOpacityFactor(0.5),
            itemBuilder: (context, _) =>
                Icon(MingCuteIcons.mgc_star_fill, color: Colors.amber[600]),
            onRatingUpdate: onRatingUpdate != null
                ? (newRate) => onRatingUpdate!(newRate * 2)
                : (_) {},
          )
        // 评分栏指示器，不能点击star来评分
        : RatingBarIndicator(
            rating: _rate,
            itemSize: iconSize ?? 20,
            itemPadding: EdgeInsets.only(right: spacing ?? 5),
            unratedColor: Colors.grey.withOpacityFactor(0.5),
            itemBuilder: (BuildContext context, int index) =>
                Icon(MingCuteIcons.mgc_star_fill, color: Colors.amber[600]),
          );
  }
}
