import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/components/dialog/dialog_confirm_migrate.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_tag.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:transparent_image/transparent_image.dart';

typedef Callback = Future<bool> Function();

// 水平排列动漫封面
// 使用：聚合搜索页
// ignore: must_be_immutable
class AnimeHorizontalCover extends StatefulWidget {
  List<Anime> animes;
  int animeId;
  // Future<bool> Function callback;
  Callback callback;
  AnimeHorizontalCover(
      {Key? key,
      required this.animes,
      this.animeId = 0,
      required this.callback})
      : super(key: key);

  @override
  State<AnimeHorizontalCover> createState() => _AnimeHorizontalCoverState();
}

class _AnimeHorizontalCoverState extends State<AnimeHorizontalCover> {
  // 275/198
  final _coverHeight = 137.0, _coverWidth = 99.0;
  bool ismigrate = false;

  @override
  void initState() {
    super.initState();
    ismigrate = widget.animeId > 0 ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animes.isEmpty) {
      return const Center(
        child: Text("暂无数据"),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      height: _coverHeight + 60, // 设置高度
      // color: Colors.redAccent,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.animes.length,
          itemBuilder: (context, animeIndex) {
            Anime anime = widget.animes[animeIndex];

            return MaterialButton(
              padding: Platform.isAndroid
                  ? const EdgeInsets.fromLTRB(5, 5, 5, 5)
                  : const EdgeInsets.fromLTRB(15, 5, 15, 5),
              // padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
              onPressed: () async {
                // Navigator.of(context).push(FadeRoute(builder: (context) {
                //   return AnimeDetailPlus(
                //     anime.animeId,
                //     parentAnime: anime,
                //   );
                // }));
                // 迁移动漫
                if (ismigrate) {
                  // 迁移提示
                  showDialogOfConfirmMigrate(context, widget.animeId, anime);
                } else if (anime.isCollected()) {
                  debugPrint("进入动漫详细页面${anime.animeId}");
                  Navigator.of(context).push(
                    FadeRoute(
                      builder: (context) {
                        return AnimeDetailPlus(anime.animeId);
                      },
                    ),
                  ).then((value) async {
                    // 使用widget.animes[animeIndex]而不是anime，才可以看到变化，比如完成集数
                    // widget.animes[animeIndex] =
                    //     await SqliteUtil.getAnimeByAnimeId(anime.animeId);
                    // setState(() {});
                    widget.callback().then((value) {
                      debugPrint("callback.then");
                      setState(() {});
                    });
                  });
                } else {
                  debugPrint("添加动漫");
                  dialogSelectTag(setState, context, anime);
                }
              },
              // 封面+动漫名
              child: Flex(
                direction: Axis.vertical,
                children: [
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      // 渐变图片，如果断网，则显示向右滑动后，左边的图片又会显示失败
                      // 可能传入的自定义动漫没有封面链接，此时需要显示文字
                      child: anime.animeCoverUrl.isEmpty
                          ? Container(
                              color: Colors.white,
                              height: _coverHeight,
                              width: _coverWidth,
                              child: Image.asset(
                                  "assets/images/defaultAnimeCover.png"),
                            )
                          : FadeInImage(
                              placeholder: MemoryImage(kTransparentImage),
                              image: NetworkImage(anime.animeCoverUrl),
                              height: _coverHeight,
                              width: _coverWidth,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 200),
                              imageErrorBuilder: (context, error, stackTrace) =>
                                  Placeholder(
                                fallbackHeight: _coverHeight,
                                fallbackWidth: _coverWidth,
                              ), // 窄高度，不会随FadeInImage里设置的宽高，需要指出宽高
                            ),
                      // 普通图片
                      // child: Image.network(anime.animeCoverUrl,
                      //     height: _coverHeight, width: _coverWidth)),
                      // 缓存图片(增大应用体积大小，因此没有使用)
                      // child: CachedNetworkImage(
                      //   imageUrl: anime.animeCoverUrl,
                      //   height: _coverHeight,
                      //   width: _coverWidth,
                      //   errorWidget: (context, url, error) =>
                      //       const Placeholder(), // 会随CachedNetworkImage里设置的宽高
                      // ),
                    ),
                    _displayEpisodeState(anime),
                    _displayReviewNumber(anime),
                  ]),
                  Container(
                    width: _coverWidth,
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      anime.animeName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textScaleFactor: 0.9,
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }

  _displayEpisodeState(Anime anime) {
    if (anime.animeId == 0) return Container(); // 没有id，说明未添加

    return Positioned(
        left: 5,
        top: 5,
        child: Container(
          // height: 20,
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Colors.blue,
          ),
          child: Text(
            "${anime.checkedEpisodeCnt}/${anime.animeEpisodeCnt}",
            textScaleFactor: 0.9,
            style: const TextStyle(color: Colors.white),
          ),
        ));
  }

  _displayReviewNumber(Anime anime) {
    if (anime.animeId == 0) return Container(); // 没有id，说明未添加

    return anime.reviewNumber == 1
        ? Container()
        : Positioned(
            right: 5,
            top: 5,
            child: Container(
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.orange,
              ),
              child: Text(
                " ${anime.reviewNumber} ",
                textScaleFactor: 0.9,
                style: const TextStyle(color: Colors.white),
              ),
            ));
  }
}
