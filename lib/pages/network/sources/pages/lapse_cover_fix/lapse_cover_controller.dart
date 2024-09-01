import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/data_state.dart';
import 'package:flutter_test_future/models/params/page_params.dart';
import 'package:flutter_test_future/widgets/progress.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/dio_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:get/get.dart';
import 'package:queue/queue.dart';

class LapseCoverController extends GetxController {
  List<Anime> coverAnimes = []; // 失效封面的动漫
  final detectProgressController = ProgressController(total: 0);
  bool hasDetected = false;
  bool loadOk = false;

  bool fixing = false; // 修复封面中
  Map<int, DataState<String>> states = {};
  final fixProgressController = ProgressController(total: 0);

  bool get mockDetect => Global.isRelease ? false : true;
  bool get mockFix => Global.isRelease ? false : false;

  Queue _createQueue() {
    return Queue(
      delay: const Duration(seconds: 3),
      parallel: 5,
    );
  }

  Future<void> detectAnimes() async {
    if (fixing) {
      ToastUtil.showText('正在修复封面');
      return;
    }
    hasDetected = true;
    loadOk = false;
    update();

    detectProgressController.count = 0;
    detectProgressController.total = await AnimeDao.getTotal();

    coverAnimes.clear();
    await _detectAnimes();
    coverAnimes.sort(
      (a, b) => a.getAnimeSource().compareTo(b.getAnimeSource()),
    );
    loadOk = true;
    update();
  }

  Future<void> _detectAnimes() async {
    PageParams page = PageParams(pageSize: 50);

    final Queue queue = _createQueue();
    while (mockDetect ? page.pageIndex < 1 : true) {
      List<Anime> animes = await AnimeDao.getAnimes(page: page);
      if (animes.isEmpty) break;

      for (final anime in animes) {
        queue.add<bool>(() => detectAnime(anime)).then((isOk) {
          detectProgressController.count++;
          if (!isOk) {
            Log.info('失效封面: ${anime.animeName} (${anime.animeCoverUrl})');
            coverAnimes.add(anime);
            update();
          }
        });
      }
      await queue.onComplete;
      page.pageIndex++;
    }
    Log.info('检测结束，共发现${coverAnimes.length}个失效封面');
  }

  Future<bool> detectAnime(Anime anime) async {
    Log.info('detect ${anime.animeName} (${anime.animeCoverUrl})');
    if (anime.animeCoverUrl.startsWith('http')) {
      if (mockDetect) {
        return DateTime.now().microsecondsSinceEpoch % 3 == 0;
      } else {
        return DioUtil.urlResponseOk(anime.animeCoverUrl);
      }
    } else {
      return true;
    }
  }

  Future<void> fixCovers() async {
    if (fixing) {
      ToastUtil.showText("修复中");
      return;
    }

    fixing = true;
    states.clear();
    for (final anime in coverAnimes) {
      states[anime.animeId] = DataState.data('等待中');
    }
    update();

    fixProgressController.count = 0;
    fixProgressController.total = coverAnimes.length;

    final Queue queue = _createQueue();
    for (int i = 0; i < coverAnimes.length; i++) {
      final anime = coverAnimes[i];

      queue.add(() async {
        states[anime.animeId] = DataState.loading();
        update();

        if (mockFix) {
          await 200.milliseconds.delay();
        } else {
          final newAnime = await ClimbAnimeUtil.climbAnimeInfoByUrl(anime,
              showMessage: false);
          coverAnimes[i] = newAnime;
          AnimeDao.updateAnimeCoverUrl(anime.animeId, anime.animeCoverUrl);
        }
        states[anime.animeId] = DataState.data('');
        update();
        fixProgressController.count++;
      });
    }
    await queue.onComplete;
    fixing = false;
    update();
    ToastUtil.showText("封面修复完毕");
  }
}
