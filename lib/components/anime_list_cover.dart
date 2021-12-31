import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';

class AnimeListCover extends StatelessWidget {
  final Anime _anime;
  const AnimeListCover(this._anime, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
      child: AspectRatio(
        aspectRatio: 1 / 1, // 正方形
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: _anime.animeCoverUrl.isEmpty
              ? null
              : CachedNetworkImage(
                  imageUrl: _anime.animeCoverUrl,
                  fit: BoxFit.fitWidth,
                ),
        ),
      ),
    );
  }
}
