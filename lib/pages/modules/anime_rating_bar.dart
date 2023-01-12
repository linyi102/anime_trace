import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class AnimeRatingBar extends StatelessWidget {
  const AnimeRatingBar(
      {required this.rate,
      required this.onRatingUpdate,
      this.enableRate = true,
      this.iconSize,
      this.spacing,
      Key? key})
      : super(key: key);
  final int rate;
  final double? iconSize;
  final double? spacing;
  final bool enableRate;
  final void Function(double) onRatingUpdate;

  @override
  Widget build(BuildContext context) {
    return enableRate
        ? RatingBar.builder(
            // 拖拽星级时会发出绿色光，所以屏蔽掉
            glow: false,
            initialRating: rate.toDouble(),
            itemSize: iconSize ?? 20,
            itemPadding: EdgeInsets.only(right: spacing ?? 5),
            unratedColor: Colors.grey.withOpacity(0.5),
            itemBuilder: (context, _) =>
                Icon(EvaIcons.star, color: Colors.amber[600]),
            onRatingUpdate: onRatingUpdate)
        // 评分栏指示器，不能点击star来评分
        : RatingBarIndicator(
            rating: rate.toDouble(),
            itemSize: iconSize ?? 20,
            itemPadding: EdgeInsets.only(right: spacing ?? 5),
            unratedColor: Colors.grey.withOpacity(0.5),
            itemBuilder: (BuildContext context, int index) =>
                Icon(EvaIcons.star, color: Colors.amber[600]),
          );
  }
}
