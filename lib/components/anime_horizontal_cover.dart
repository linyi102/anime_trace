import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/components/select_tag_dialog.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_detail.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:transparent_image/transparent_image.dart';

class AnimeHorizontalCover extends StatefulWidget {
  List<Anime> animes;
  bool ismigrate;
  int animeId;
  AnimeHorizontalCover(
      {Key? key,
      required this.animes,
      this.ismigrate = false,
      this.animeId = 0})
      : super(key: key);

  @override
  State<AnimeHorizontalCover> createState() => _AnimeHorizontalCoverState();
}

class _AnimeHorizontalCoverState extends State<AnimeHorizontalCover> {
  // 275/198
  final _coverHeight = 137.0, _coverWidth = 99.0;

  @override
  Widget build(BuildContext context) {
    if (widget.animes.isEmpty) {
      return const Center(
        child: Text("暂无数据"),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      height: _coverHeight + 60, // 设置高度
      // color: Colors.redAccent,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.animes.length,
          itemBuilder: (context, animeIndex) {
            Anime anime = widget.animes[animeIndex];

            return MaterialButton(
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
              onPressed: () async {
                // Navigator.of(context).push(FadeRoute(builder: (context) {
                //   return AnimeDetailPlus(
                //     anime.animeId,
                //     parentAnime: anime,
                //   );
                // }));
                // 迁移动漫
                if (widget.ismigrate) {
                  debugPrint("迁移动漫${widget.animeId}");
                  // SqliteUtil.updateAnimeCoverbyAnimeId(
                  //     widget.animeId, anime.animeCoverUrl);
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("提示"),
                        content: const Text("确定迁移吗？"),
                        actions: [
                          TextButton(
                            child: const Text("取消"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          ElevatedButton(
                              onPressed: () async {
                                SqliteUtil.updateAnime(
                                        await SqliteUtil.getAnimeByAnimeId(
                                            widget.animeId),
                                        anime)
                                    .then((value) {
                                  // 关闭对话框
                                  Navigator.pop(context);
                                  // 更新完毕(then)后，退回到详细页，然后重新加载数据才会看到更新
                                  Navigator.pop(context);
                                });
                              },
                              child: const Text("确认"))
                        ],
                      );
                    },
                  );
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
                    widget.animes[animeIndex] =
                        await SqliteUtil.getAnimeByAnimeId(anime.animeId);
                    setState(() {});
                  });
                } else {
                  debugPrint("添加动漫");
                  dialogSelectTag(setState, context, anime);
                }
              },
              child: Flex(
                direction: Axis.vertical,
                children: [
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      // 渐变图片
                      child: FadeInImage(
                        placeholder: MemoryImage(kTransparentImage),
                        image: NetworkImage(anime.animeCoverUrl),
                        height: _coverHeight,
                        width: _coverWidth,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 200),
                        imageErrorBuilder: (context, error, stackTrace) =>
                            const Placeholder(),
                      ),
                      // 普通图片
                      // child: Image.network(anime.animeCoverUrl,
                      //     height: _coverHeight, width: _coverWidth)),
                      // 缓存图片
                      // child: CachedNetworkImage(
                      //   imageUrl: anime.animeCoverUrl,
                      //   height: _coverHeight,
                      //   width: _coverWidth,
                      //   errorWidget: (context, url, error) =>
                      //       const Placeholder(),
                      // )
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
