import 'package:flutter/material.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';

import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/viewer/network_image/network_image_page.dart';
import 'package:flutter_test_future/routes/get_route.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/utils/log.dart';

showDialogOfConfirmMigrate(parentContext, int animeId, Anime newAnime) {
  Log.info("迁移动漫$animeId");
  bool updateName =
      SPUtil.getBool("updateNameInMigratePage", defaultValue: true);
  bool updateCover =
      SPUtil.getBool("updateCoverInMigratePage", defaultValue: true);
  bool updateInfo =
      SPUtil.getBool("updateInfoInMigratePage", defaultValue: true);
  bool updateAnimeUrl =
      SPUtil.getBool("updateAnimeUrlInMigratePage", defaultValue: true);

  // 如果已添加，则不能迁移到该动漫
  if (newAnime.isCollected()) {
    ToastUtil.showText("该动漫已收藏，不能迁移");
    return;
  }
  // 迁移提示
  showDialog(
    context: parentContext,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, dialogState) {
          return AlertDialog(
            title: const Text("迁移设置"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.all(0),
                    style: ListTileStyle.drawer,
                    dense: true,
                    title: const Text("更新名字"),
                    subtitle: Text(newAnime.animeName),
                    leading: IconButton(
                      onPressed: () {
                        dialogState(() {
                          updateName = !updateName;
                        });
                        SPUtil.setBool("updateNameInMigratePage", updateName);
                      },
                      icon: updateName
                          ? Icon(Icons.check_box,
                              color: Theme.of(context).primaryColor)
                          : const Icon(Icons.check_box_outline_blank),
                    ),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.all(0),
                    style: ListTileStyle.drawer,
                    dense: true,
                    title: const Text("更新封面"),
                    subtitle: const Text("查看新封面"),
                    onTap: () {
                      RouteUtil.toImageViewer(context,
                          NetworkImageViewPage(newAnime.animeCoverUrl));
                    },
                    leading: IconButton(
                        onPressed: () {
                          dialogState(() {
                            updateCover = !updateCover;
                          });
                          SPUtil.setBool(
                              "updateCoverInMigratePage", updateCover);
                        },
                        icon: updateCover
                            ? Icon(Icons.check_box,
                                color: Theme.of(context).primaryColor)
                            : const Icon(Icons.check_box_outline_blank)),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.all(0),
                    style: ListTileStyle.drawer,
                    dense: true,
                    title: const Text("更新动漫信息"),
                    leading: IconButton(
                      onPressed: () {
                        dialogState(() {
                          updateInfo = !updateInfo;
                        });
                        SPUtil.setBool("updateInfoInMigratePage", updateInfo);
                      },
                      icon: updateInfo
                          ? Icon(Icons.check_box,
                              color: Theme.of(context).primaryColor)
                          : const Icon(Icons.check_box_outline_blank),
                    ),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.all(0),
                    style: ListTileStyle.drawer,
                    dense: true,
                    title: const Text("更新网址"),
                    leading: IconButton(
                      onPressed: () {
                        dialogState(() {
                          updateAnimeUrl = !updateAnimeUrl;
                        });
                        SPUtil.setBool(
                            "updateAnimeUrlInMigratePage", updateAnimeUrl);
                      },
                      icon: updateAnimeUrl
                          ? Icon(Icons.check_box,
                              color: Theme.of(context).primaryColor)
                          : const Icon(Icons.check_box_outline_blank),
                    ),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("取消"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton(
                  onPressed: () async {
                    // 关闭对话框
                    Navigator.pop(context);

                    // 获取详细信息
                    if (updateInfo) {
                      var closeLoading = ToastUtil.showLoading(msg: '获取信息中...');
                      newAnime =
                          await ClimbAnimeUtil.climbAnimeInfoByUrl(newAnime);
                      closeLoading();
                    }

                    AnimeDao.updateAnime(
                        await SqliteUtil.getAnimeByAnimeId(animeId), newAnime,
                        updateCover: updateCover,
                        updateInfo: updateInfo,
                        updateName: updateName,
                        updateAnimeUrl: updateAnimeUrl);
                    Navigator.pop(parentContext);
                  },
                  child: const Text("迁移"))
            ],
          );
        },
      );
    },
  );
}
