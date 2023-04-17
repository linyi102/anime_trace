import 'package:flutter/material.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/play_status.dart';
import 'package:flutter_test_future/pages/anime_detail/controllers/anime_controller.dart';

showDialogSelectPlayStatus(
    BuildContext context, AnimeController animeController) {
  showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text("播放状态"),
          contentPadding: const EdgeInsets.all(8),
          children: PlayStatus.values
              .map((playStatus) => ListTile(
                    leading: playStatus == animeController.anime.getPlayStatus()
                        ? Icon(Icons.radio_button_on,
                            color: Theme.of(context).primaryColor)
                        : const Icon(Icons.radio_button_off),
                    title: Text(playStatus.text),
                    trailing: Icon(playStatus.iconData),
                    onTap: () {
                      animeController.anime.playStatus = playStatus.text;
                      animeController.updateAnimeInfo();
                      AnimeDao.updateAnimePlayStatusByAnimeId(
                          animeController.anime.animeId, playStatus.text);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        );
      });
}
