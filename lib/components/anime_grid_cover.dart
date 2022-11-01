import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:get/get.dart';
import 'package:transparent_image/transparent_image.dart';

import '../controllers/anime_display_controller.dart';

// 用于显示完整的动漫封面
// 包括进度、第几次观看、名字
class AnimeGridCover extends StatelessWidget {
  final Anime _anime;
  final bool onlyShowCover; // 动漫详细页只显示封面
  final double coverWidth; // 传入固定宽度，用于水平列表

  const AnimeGridCover(this._anime,
      {Key? key, this.onlyShowCover = false, this.coverWidth = 0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AnimeDisplayController _animeDisplayController = Get.find();

    return onlyShowCover
        ? _buildCover(context, false)
        : Obx(() => Column(
              children: [
                // 封面
                Stack(
                  children: [
                    _buildCover(
                        context,
                        _animeDisplayController.showGridAnimeName.value &&
                            _animeDisplayController.showNameInCover.value),
                    _buildEpisodeState(_anime.isCollected() &&
                        _animeDisplayController.showGridAnimeProgress.value),
                    _buildReviewNumber(_anime.isCollected() &&
                        _animeDisplayController.showReviewNumber.value &&
                        _anime.reviewNumber > 1)
                  ],
                ),
                // 名字
                _buildNameBelowCover(
                    _animeDisplayController.showNameBelowCover),
              ],
            ));
  }

  _buildCover(BuildContext context, bool showNameInCover) {
    return Container(
        width: coverWidth == 0 ? null : coverWidth,
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
        ),
        child: AspectRatio(
          // 固定宽高比
          aspectRatio: 198 / 275,
          // aspectRatio: 31 / 45,
          // aspectRatio: 41 / 63,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                // 确保图片填充
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: _buildCoverImg(),
                ),
                _buildNameInCover(showNameInCover)
              ],
            ),
          ),
        ));
  }

  _buildEpisodeState(bool show) {
    if (show) {
      return Positioned(
          left: 5,
          top: 5,
          child: Container(
            // height: 20,
            padding: const EdgeInsets.fromLTRB(3, 2, 3, 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: ThemeUtil.getThemePrimaryColor(),
            ),
            child: Text(
              "${_anime.checkedEpisodeCnt}/${_anime.animeEpisodeCnt}",
              textScaleFactor: 0.8,
              style: const TextStyle(color: Colors.white),
            ),
          ));
    } else {
      return Container();
    }
  }

  _buildReviewNumber(bool show) {
    if (show) {
      return Positioned(
          right: 5,
          top: 5,
          child: Container(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3), color: Colors.orange),
            child: Text(" ${_anime.reviewNumber} ",
                textScaleFactor: 0.8,
                style: const TextStyle(color: Colors.white)),
          ));
    } else {
      return Container();
    }
  }

  _buildCoverImg() {
    if (_anime.animeCoverUrl.isEmpty) {
      return Container(
        color: ThemeUtil.getAppBarBackgroundColor(),
        child: Center(
          child: Text(
            _anime.animeName.substring(
                0,
                _anime.animeName.length > 3 // 最低长度为3，此时下标最大为2，才可以设置end为3，[0, 3)
                    ? 3
                    : _anime.animeName.length), // 第二个参数如果只设置为3可能会导致越界
            textScaleFactor: 1.3,
            style: TextStyle(color: ThemeUtil.getFontColor()),
          ),
        ),
      );
    }

    // 网络封面
    if (_anime.animeCoverUrl.startsWith("http")) {
      // 断网后```访问不了图片，所以使用CachedNetworkImage缓存起来
      // return FadeInImage(
      //     placeholder: MemoryImage(kTransparentImage),
      //     fit: BoxFit.cover,
      //     image: NetworkImage(
      //       _anime.animeCoverUrl,
      //     ));
      return CachedNetworkImage(
        // memCacheHeight: 500,
        imageUrl: _anime.animeCoverUrl,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => Image.memory(kTransparentImage),
      );
    }

    // 本地封面
    return Image.file(
      File(ImageUtil.getAbsoluteCoverImagePath(_anime.animeCoverUrl)),
      fit: BoxFit.cover,
      // 这里不能使用errorImageBuilder，否则无法进入动漫封面详细页
      errorBuilder: (context, url, error) => Image.memory(kTransparentImage),
    );
  }

  _buildNameInCover(bool show) {
    if (!show) return Container();
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 80,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                    Colors.transparent,
                    Color.fromRGBO(0, 0, 0, 0.6)
                  ])),
            ),
          ],
        ),
        // 使用Align替换Positioned，可以保证在Stack下自适应父元素宽度
        Container(
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.only(bottom: 5),
          child: Container(
            // TODO 字体溢出，没有换行，可能是因为Stack，Container没有宽度限制
            padding: const EdgeInsets.fromLTRB(5, 0, 10, 5),
            child: Text(
              _anime.animeName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textScaleFactor: 0.9,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        )
      ],
    );
  }

  _buildNameBelowCover(bool show) {
    return show
        ? Container(
            width: coverWidth == 0 ? null : coverWidth,
            padding: const EdgeInsets.only(top: 2, left: 3, right: 3),
            // 保证文字左对齐
            alignment: Alignment.centerLeft,
            child: Text(_anime.animeName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textScaleFactor: 0.9,
                style: TextStyle(color: ThemeUtil.getFontColor())))
        : Container();
  }
}
