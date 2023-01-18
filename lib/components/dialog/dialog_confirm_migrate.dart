import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_test_future/utils/log.dart';

import '../loading_dialog.dart';

showDialogOfConfirmMigrate(parentContext, int animeId, Anime newAnime) {
  Log.info("迁移动漫$animeId");
  bool migrateCover = true;

  // 如果已添加，则不能迁移到该动漫
  if (newAnime.isCollected()) {
    showToast("该动漫已收藏，不能迁移");
    return;
  }
  // 迁移提示
  showDialog(
    context: parentContext,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, dialogState) {
          return AlertDialog(
            title: const Text("确定迁移吗？"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.all(0),
                    title: const Text("迁移到："),
                    subtitle: Text(newAnime.animeName),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.all(0),
                    style: ListTileStyle.drawer,
                    dense: true,
                    title: const Text("包括封面"),
                    leading: migrateCover
                        ? Icon(Icons.check_box,
                            color: ThemeUtil.getPrimaryIconColor())
                        : const Icon(Icons.check_box_outline_blank),
                    onTap: () {
                      migrateCover = !migrateCover;
                      dialogState(() {});
                    },
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("取消"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                  onPressed: () async {
                    // 获取详细信息
                    BuildContext? loadingContext;
                    showDialog(
                        context: context, // 页面context
                        builder: (context) {
                          // 对话框context
                          loadingContext =
                              context; // 将对话框context赋值给变量，用于任务完成后完毕
                          return const LoadingDialog("获取详细信息中...");
                        });

                    newAnime =
                        await ClimbAnimeUtil.climbAnimeInfoByUrl(newAnime);
                    await SqliteUtil.updateAnime(
                        await SqliteUtil.getAnimeByAnimeId(animeId), newAnime,
                        migrateCover: migrateCover);

                    // 关闭加载框
                    if (loadingContext != null) Navigator.pop(loadingContext!);
                    // 关闭对话框
                    Navigator.pop(context);
                    // 退回到详细页
                    Navigator.pop(parentContext);
                  },
                  child: const Text("确定"))
            ],
          );
        },
      );
    },
  );
}
