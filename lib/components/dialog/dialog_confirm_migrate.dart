import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:oktoast/oktoast.dart';

showDialogOfConfirmMigrate(parentContext, int animeId, Anime newAnime) {
  debugPrint("迁移动漫$animeId");
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
            title: const Text("提示"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  const ListTile(title: Text("确定迁移吗？")),
                  ListTile(
                    style: ListTileStyle.drawer,
                    dense: true,
                    title: const Text("包括封面"),
                    leading: migrateCover
                        ? Icon(Icons.check_box, color: ThemeUtil.getPrimaryIconColor())
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
                    SqliteUtil.updateAnime(
                            await SqliteUtil.getAnimeByAnimeId(animeId),
                            newAnime,
                            migrateCover: migrateCover)
                        .then((value) {
                      // 关闭对话框
                      Navigator.pop(context);
                      // 更新完毕(then)后，退回到详细页，然后重新加载数据才会看到更新
                      Navigator.pop(parentContext);
                    });
                  },
                  child: const Text("确认"))
            ],
          );
        },
      );
    },
  );
}
