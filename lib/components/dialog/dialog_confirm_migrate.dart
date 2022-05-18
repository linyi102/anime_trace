import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:oktoast/oktoast.dart';

showDialogOfConfirmMigrate(parentContext, int animeId, Anime newAnime) {
  debugPrint("迁移动漫$animeId");

  // 如果已添加，则不能迁移到该动漫
  if (newAnime.isCollected()) {
    showToast("该动漫已收藏，不能迁移");
    return;
  }
  // 迁移提示
  showDialog(
    context: parentContext,
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
                        await SqliteUtil.getAnimeByAnimeId(animeId), newAnime)
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
}
