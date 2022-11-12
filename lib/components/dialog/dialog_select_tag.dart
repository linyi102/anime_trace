import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:oktoast/oktoast.dart';

import '../../utils/climb/climb_anime_util.dart';

dialogSelectTag(setState, context, Anime anime) {
  bool climbingDetail = false;
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      List<Widget> items = [];
      // items.add(ListTile(
      //   style: ListTileStyle.drawer,
      //   title: Text(anime.animeName),
      //   textColor: ThemeUtil.getCommentColor(),
      // ));
      for (int i = 0; i < tags.length; ++i) {
        items.add(
          ListTile(
            title: Text(tags[i]),
            leading: tags[i] == anime.tagName
                ? Icon(
                    Icons.radio_button_on_outlined,
                    color: ThemeUtil.getPrimaryColor(),
                  )
                : const Icon(
                    Icons.radio_button_off_outlined,
                  ),
            enabled: !climbingDetail,
            onTap: () async {
              // 不能只传入tagName，需要把对象的引用传进来，然后修改就会生效
              // 如果起初没有收藏，则说明是新增，否则修改
              if (!anime.isCollected()) {
                anime.tagName = tags[i];
                if (anime.animeUrl.contains("yhdm") ||
                    anime.animeUrl.contains("age")) {
                  // 如果是樱花和age，则不需要首次更新详细页
                } else {
                  // 不允许点击，避免快速多次点击收藏
                  climbingDetail = true;
                  (dialogContext as Element).markNeedsBuild();
                  // 爬取详细页
                  anime = await ClimbAnimeUtil.climbAnimeInfoByUrl(anime,
                      showMessage: false);
                }

                // 插入数据库
                anime.animeId = await SqliteUtil.insertAnime(anime);
                Navigator.pop(dialogContext);
                // 更新父级页面
                setState(() {});
                showToast("收藏成功！");
              } else {
                SqliteUtil.updateTagByAnimeId(anime.animeId, tags[i]);
                anime.tagName = tags[i];
                showToast("修改成功！");
                setState(() {});
                Navigator.pop(dialogContext);
              }
            },
          ),
        );
      }
      return AlertDialog(
        title: const Text('选择清单'),
        content: SingleChildScrollView(
          child: climbingDetail
              ? Center(
                  child: Column(
                  children: const [
                    SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator()),
                    SizedBox(height: 10),
                    Text("正在获取详细信息...", textScaleFactor: 0.8)
                  ],
                ))
              : Column(children: items),
        ),
      );
    },
  );
}
