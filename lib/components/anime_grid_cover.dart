import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/utils/theme_util.dart';

class AnimeGridCover extends StatelessWidget {
  final Anime _anime;
  const AnimeGridCover(this._anime, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(3.0),
        child: AspectRatio(
          // 固定大小
          aspectRatio: 198 / 275,
          // aspectRatio: 31 / 45,
          // aspectRatio: 41 / 63,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: _anime.animeCoverUrl.isEmpty
                // ? Image.asset("assets/images/defaultAnimeCover.png")
                // ? Image.memory(kTransparentImage)
                ? Container(
                    color: ThemeUtil.getAppBarBackgroundColor(),
                    child: Center(
                      child: Text(
                        _anime.animeName.substring(
                            0,
                            _anime.animeName.length >
                                    3 // 最低长度为3，此时下标最大为2，才可以设置end为3，[0, 3)
                                ? 3
                                : _anime
                                    .animeName.length), // 第二个参数如果只设置为3可能会导致越界
                        textScaleFactor: 1.3,
                        style: TextStyle(color: ThemeUtil.getFontColor()),
                      ),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: _anime.animeCoverUrl,
                    fit: BoxFit.fitHeight,
                    errorWidget: (context, url, error) => const Placeholder(),
                  ),
          ),
        ));
  }
}
