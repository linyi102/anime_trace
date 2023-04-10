import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/anime_detail/controllers/anime_controller.dart';

import '../../models/play_status.dart';
import '../../utils/sqlite_util.dart';

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
                        leading:
                            playStatus == animeController.anime.getPlayStatus()
                                ? Icon(Icons.radio_button_on,
                                    color: Theme.of(context).primaryColor)
                                : const Icon(Icons.radio_button_off),
                        title: Text(playStatus.text),
                        trailing: Icon(playStatus.iconData),
                        onTap: () {
                          animeController.anime.playStatus = playStatus.text;
                          animeController.updateAnimeInfo();
                          SqliteUtil.updateAnimePlayStatusByAnimeId(
                              animeController.anime.animeId, playStatus.text);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      });
}
