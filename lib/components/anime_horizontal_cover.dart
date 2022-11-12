import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/dialog/dialog_confirm_migrate.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_tag.dart';
import 'package:flutter_test_future/controllers/anime_display_controller.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:get/get.dart';

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
    final AnimeDisplayController animeDisplayController = Get.find();
    if (widget.animes.isEmpty) {
      return const Center(child: Text("什么都没有~"));
    }
    double height = _coverHeight;
    bool nameBelowCover = false; // 名字在封面下面，就增加高度
    if (animeDisplayController.showGridAnimeName.value &&
        !animeDisplayController.showNameInCover.value) {
      nameBelowCover = true;
    }
    if (nameBelowCover) {
      height += 60;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      height: height, // 设置高度
      // color: Colors.redAccent,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.animes.length,
          itemBuilder: (context, animeIndex) {
            Anime anime = widget.animes[animeIndex];

            return MaterialButton(
              padding: const EdgeInsets.all(0),
              onPressed: () async {
                // 迁移动漫
                if (ismigrate) {
                  // 迁移提示
                  showDialogOfConfirmMigrate(context, widget.animeId, anime);
                } else if (anime.isCollected()) {
                  debugPrint("进入动漫详细页面${anime.animeId}");
                  Navigator.of(context).push(
                    FadeRoute(
                      builder: (context) {
                        return AnimeDetailPlus(anime);
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
              child: AnimeGridCover(anime, coverWidth: _coverWidth),
            );
          }),
    );
  }
}
