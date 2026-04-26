import 'package:animetrace/dao/episode_desc_dao.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/episode.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:animetrace/utils/extensions/color.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

/// 动漫评分栏
/// 范围 [0, 1, 2, ..., 10]
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
  final void Function(int value)? onRatingUpdate;

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
                ? (newRate) => onRatingUpdate!((newRate * 2).toInt())
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

/// 集评分栏
/// 范围 [0, 0.5, 1, 1.5, ..., 5]
class EpisodeRatingBar extends StatelessWidget {
  const EpisodeRatingBar({
    super.key,
    required this.anime,
    required this.episode,
    this.onChanged,
  });
  final Anime anime;
  final Episode episode;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      glow: false,
      allowHalfRating: true,
      initialRating: episode.desc?.rate ?? 0,
      itemSize: 24,
      itemPadding: const EdgeInsets.symmetric(horizontal: 4),
      unratedColor: Colors.grey.withOpacityFactor(0.5),
      itemBuilder: (context, _) =>
          Icon(MingCuteIcons.mgc_star_fill, color: Colors.amber[600]),
      onRatingUpdate: (value) async {
        if (episode.desc == null) {
          final desc = EpisodeDesc(
            id: 0,
            animeId: anime.animeId,
            number: episode.number,
            rate: value,
          );
          desc.id = await EpisodeDescDao.insert(desc);
          if (desc.id <= 0) {
            ToastUtil.showText('评分创建失败');
            return;
          }
          episode.desc = desc;
        } else {
          episode.desc!.rate = value;
          final r = await EpisodeDescDao.update(episode.desc!);
          if (r < 1) {
            ToastUtil.showText('评分更新失败');
            return;
          }
        }
        onChanged?.call(value);
      },
    );
  }
}
