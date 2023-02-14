import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_dialog.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';

dialogSelectChecklist(
  setState,
  context,
  Anime anime, {
  bool onlyShowChecklist = false, // 只显示清单列表
  bool enableClimbDetailInfo = true, // 开启爬取详细信息
  void Function(Anime newAnime)? callback,
}) {
  bool climbingDetail = false;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      List<Widget> items = [];
      if (!anime.isCollected() && !onlyShowChecklist) {
        items.add(_buildCommonItem(content: "动漫名字", isTitle: true));
        items.add(_buildCommonItem(content: anime.animeName));
        items.add(_buildCommonItem(content: "选择清单", isTitle: true));
      }
      for (int i = 0; i < tags.length; ++i) {
        items.add(
          ListTile(
            contentPadding: EdgeInsetsDirectional.zero,
            dense: true,
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
                // 如果传入的就是不更新，那么就不爬取详细页
                if (!enableClimbDetailInfo) {
                } else {
                  climbingDetail = true; // 不允许点击，避免快速多次点击收藏
                  (context as Element).markNeedsBuild();
                  // 爬取详细页
                  anime = await ClimbAnimeUtil.climbAnimeInfoByUrl(anime,
                      showMessage: false);
                }

                // 插入数据库
                anime.animeId = await SqliteUtil.insertAnime(anime);
                Navigator.pop(context);
                // 更新父级页面
                setState(() {});
                // showToast("收藏成功！");
                if (callback != null) {
                  callback(anime);
                }
              } else {
                SqliteUtil.updateTagByAnimeId(anime.animeId, tags[i]);
                anime.tagName = tags[i];
                // showToast("修改成功！");
                setState(() {});
                Navigator.pop(context);
              }
            },
          ),
        );
      }
      if (climbingDetail) {
        return const LoadingDialog("获取详细信息中...");
      }
      return AlertDialog(
        title: const Text('选择清单'),
        content: SingleChildScrollView(
          child: Column(children: items),
        ),
      );
    },
  );
}

_buildCommonItem({required String content, bool isTitle = false}) {
  return ListTile(
    contentPadding: EdgeInsetsDirectional.zero,
    dense: true,
    title: Text(content),
    textColor: isTitle ? ThemeUtil.getCommentColor() : null,
  );
}
