import 'package:flutter/material.dart';
import 'package:animetrace/dao/anime_dao.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/pages/anime_collection/checklist_controller.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/climb/climb_anime_util.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:animetrace/widgets/bottom_sheet.dart';

dialogSelectChecklist(
  setState,
  context,
  Anime anime, {
  bool onlyShowChecklist = false, // 只显示清单列表
  bool enableClimbDetailInfo = true, // 开启爬取详细信息
  void Function(Anime newAnime)? callback,
}) {
  List<Widget> items = [];
  if (!anime.isCollected() && !onlyShowChecklist) {
    items.add(ListTile(title: SelectableText(anime.animeName)));
  }
  var tags = ChecklistController.to.tags;

  for (int i = 0; i < tags.length; ++i) {
    items.add(
      ListTile(
        title: Text(tags[i]),
        leading: tags[i] == anime.tagName
            ? Icon(Icons.radio_button_on_outlined,
                color: Theme.of(context).primaryColor)
            : const Icon(Icons.radio_button_off_outlined),
        onTap: () async {
          // 不能只传入tagName，需要把对象的引用传进来，然后修改就会生效
          // 如果起初没有收藏，则说明是新增，否则修改
          if (!anime.isCollected()) {
            anime.tagName = tags[i];

            // 不管怕不爬取详细页，都先关闭选择清单框
            Navigator.pop(context);

            if (enableClimbDetailInfo) {
              // 爬取详细页后收藏
              ToastUtil.showLoading(
                msg: "获取中",
                task: () async {
                  // 爬取详细页
                  anime = await ClimbAnimeUtil.climbAnimeInfoByUrl(anime,
                      showMessage: false);
                },
                onTaskComplete: (taskValue) async {
                  // 插入数据库
                  anime.animeId = await AnimeDao.insertAnime(anime);
                  // 更新父级页面
                  setState(() {});
                  Log.info("收藏成功！");
                  if (callback != null) callback(anime);
                },
              );
            } else {
              // 直接收藏
              anime.animeId = await AnimeDao.insertAnime(anime);
              setState(() {});
              Log.info("收藏成功！");
              if (callback != null) callback(anime);
            }
          } else {
            AnimeDao.updateTagByAnimeId(anime.animeId, tags[i]);
            anime.tagName = tags[i];
            Log.info("修改成功！");
            setState(() {});

            // 关闭选择清单框
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  showCommonModalBottomSheet(
    context: context,
    builder: (context) => Scaffold(
      appBar: AppBar(
        title: const Text("选择清单"),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: items,
      ),
    ),
  );
}
