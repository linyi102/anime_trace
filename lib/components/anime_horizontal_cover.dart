import 'package:flutter/material.dart';

import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/dialog/dialog_confirm_migrate.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_checklist.dart';
import 'package:flutter_test_future/controllers/anime_display_controller.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/values/theme.dart';
import 'package:get/get.dart';
import 'package:flutter_test_future/utils/log.dart';

// 水平排列动漫封面
// 使用：聚合搜索页
// ignore: must_be_immutable
class AnimeHorizontalCover extends StatefulWidget {
  List<Anime> animes;
  int animeId;

  // Future<bool> Function callback;
  Future<bool> Function() callback;

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
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: const Row(
          children: [Text("没有找到。")],
        ),
      );
    }
    final AnimeDisplayController animeDisplayController = Get.find();
    double height = _coverHeight;
    bool nameBelowCover = false; // 名字在封面下面，就增加高度
    if (animeDisplayController.showGridAnimeName.value &&
        !animeDisplayController.showNameInCover.value) {
      nameBelowCover = true;
    }
    if (nameBelowCover) {
      if (animeDisplayController.nameMaxLines.value == 2) {
        height += 60;
      } else {
        height += 30;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      height: height + 10, // 设置高度
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.animes.length,
          itemBuilder: (context, animeIndex) {
            Anime anime = widget.animes[animeIndex];

            return InkWell(
              borderRadius: BorderRadius.circular(AppTheme.imgRadius),
              onTap: () async {
                // 迁移动漫
                if (ismigrate) {
                  // 迁移提示
                  showDialogOfConfirmMigrate(context, widget.animeId, anime);
                } else if (anime.isCollected()) {
                  Log.info("进入动漫详细页面${anime.animeId}");
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return AnimeDetailPage(anime);
                      },
                    ),
                  ).then((value) async {
                    // 使用widget.animes[animeIndex]而不是anime，才可以看到变化，比如完成集数
                    // widget.animes[animeIndex] =
                    //     await SqliteUtil.getAnimeByAnimeId(anime.animeId);
                    // setState(() {});
                    widget.animes[animeIndex] = value;
                    widget.callback().then((value) {
                      Log.info("callback.then");
                      setState(() {});
                    });
                  });
                } else {
                  Log.info("");
                  dialogSelectChecklist(setState, context, anime);
                }
              },
              child: AnimeGridCover(anime, coverWidth: _coverWidth),
            );
          }),
    );
  }
}
