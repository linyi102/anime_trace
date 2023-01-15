import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/anime_controller.dart';

import '../../models/play_status.dart';
import '../../utils/sqlite_util.dart';
import '../../utils/theme_util.dart';

showDialogSelectPlayStatus(
    BuildContext context, AnimeController animeController) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("播放状态"),
          content: SingleChildScrollView(
            child: Column(
              children: PlayStatus.values
                  .map((playStatus) => ListTile(
                        leading: playStatus ==
                                animeController.anime.value.getPlayStatus()
                            ? Icon(Icons.radio_button_on,
                                color: ThemeUtil.getPrimaryIconColor())
                            : const Icon(Icons.radio_button_off),
                        title: Text(playStatus.text),
                        trailing: Icon(playStatus.iconData),
                        onTap: () {
                          animeController
                              .updateAnimePlayStatus(playStatus.text);
                          SqliteUtil.updateAnimePlayStatusByAnimeId(
                              animeController.anime.value.animeId,
                              playStatus.text);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      });
}
