import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/anime_controller.dart';

import '../../utils/sqlite_util.dart';
import '../../utils/theme_util.dart';

showDialogSelectPlayStatus(
    BuildContext context, AnimeController animeController) {
  showDialog(
      context: context,
      builder: (context) {
        String playStatus = animeController.anime.value.getPlayStatus().text;
        return AlertDialog(
          title: const  Text("播放状态"),
          content: SingleChildScrollView(
            child: Column(
              children: ["未开播", "连载中", "已完结"]
                  .map((e) => ListTile(
                        leading: e == playStatus
                            ? Icon(
                                Icons.radio_button_on,
                                color: ThemeUtil.getPrimaryIconColor(),
                              )
                            : const Icon(Icons.radio_button_off),
                        title: Text(e),
                        onTap: () {
                          animeController.updateAnimePlayStatus(e);
                          SqliteUtil.updateAnimePlayStatusByAnimeId(
                              animeController.anime.value.animeId, e);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      });
}
