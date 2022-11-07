import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:oktoast/oktoast.dart';

import '../../utils/climb/climb_anime_util.dart';

dialogSelectTag(setState, context, Anime anime) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      List<Widget> radioList = [];
      for (int i = 0; i < tags.length; ++i) {
        radioList.add(
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
            onTap: () async {
              // 不能只传入tagName，需要把对象的引用传进来，然后修改就会生效
              // 如果起初没有收藏，则说明是新增，否则修改
              if (!anime.isCollected()) {
                anime.tagName = tags[i];
                setState(() {});

                // 先关闭对话框，避免快速多次点击收藏
                Navigator.pop(context);
                // 爬取详细页
                anime = await ClimbAnimeUtil.climbAnimeInfoByUrl(anime,
                    collecting: true, showMessage: false);

                // 插入数据库
                anime.animeId = await SqliteUtil.insertAnime(anime);
                setState(() {});
                showToast("收藏成功！");

                // 第一次收藏，获取更加详细的内容
                // 在插入该动画后再更新，否则收藏时会有延迟
                // showMessage为false表示不显示更新信息成功
                // Anime oldAnime = anime.copy();
                // anime = await ClimbAnimeUtil.climbAnimeInfoByUrl(anime,
                //     collecting: true, showMessage: false);
                // SqliteUtil.updateAnime(oldAnime, anime);
              } else {
                SqliteUtil.updateTagByAnimeId(anime.animeId, tags[i]);
                anime.tagName = tags[i];
                showToast("修改成功！");
                setState(() {});
                Navigator.pop(context);
              }
            },
          ),
        );
      }
      return AlertDialog(
        title: const Text('选择清单'),
        content: SingleChildScrollView(
          child: Column(
            children: radioList,
          ),
        ),
        // actions: <Widget>[
        //   anime.isCollected()
        //       ? TextButton(
        //           child: const Text("取消收藏"),
        //           onPressed: () {
        //             if (anime.isCollected()) {
        //               SqliteUtil.deleteAnimeByAnimeId(anime.animeId);
        //               anime.animeId = 0;
        //               anime.tagName = "";
        //               setState(() {});
        //               showToast("取消成功！");
        //             }
        //             Navigator.of(context).pop();
        //           },
        //         )
        //       : Container(),
        //   TextButton(
        //     child: const Text("取消"),
        //     onPressed: () {
        //       Navigator.of(context).pop();
        //     },
        //   ),
        // ],
      );
    },
  );
}
