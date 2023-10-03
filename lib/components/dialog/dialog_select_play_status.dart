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
          children: PlayStatus.values
              .map((playStatus) => RadioListTile(
                    title: Text(playStatus.text),
                    value: animeController.anime.getPlayStatus(),
                    groupValue: playStatus,
                    onChanged: (PlayStatus? value) {
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
