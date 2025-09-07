part of 'migrate_page.dart';

class MigrateController extends GetxController {
  /// 源搜索源
  final ClimbWebsite sourceWebsite;
  MigrateController({required this.sourceWebsite});

  /// 迁移到该搜索源
  ClimbWebsite? destWebsite;

  /// 在迁移过程中，每次迁移的间隔时间(单位秒)
  int spacingSeconds = 3;

  /// 只迁移连载中或播放状态未知的动漫
  bool skipFinishedAnime = true;

  /// 动漫列表
  List<Anime> animes = [];

  /// 迁移状态(anime_id -> DataState)
  Map<int, DataState<String>> states = {};

  /// 是否正在迁移
  bool migrating = false;

  /// 迁移进度控制器
  final progressController = ProgressController(total: 0);

  /// 迁移任务，用于中断迁移
  Completer? completer;

  @override
  void onInit() {
    _loadAnimes();
    super.onInit();
  }

  @override
  void onClose() {
    _cancelMigrate();
    super.onClose();
  }

  Future<void> _loadAnimes() async {
    animes = await AnimeDao.getAnimesInSource(sourceId: sourceWebsite.id);
    update();
  }

  void updateDestWebsite(ClimbWebsite website) {
    destWebsite = website;
    update();
  }

  void updateSpacingDuration(int seconds) {
    spacingSeconds = seconds;
    update();
  }

  void updateOnlyMirgratePlaying(bool value) {
    skipFinishedAnime = value;
    update();
  }

  Future<void> onTapPrimary(BuildContext context) async {
    if (migrating) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('迁移中'),
          content: const Text('迁移任务正在进行中，是否停止迁移？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelMigrate();
              },
              child: const Text('停止'),
            ),
          ],
        ),
      );
      return;
    }

    if (destWebsite == null) {
      await _showSelectWebsite(context);
    }
    showDialog(context: context, builder: (context) => const _MigrateFormView());
  }

  Future<void> startMigrate() async {
    if (migrating) return;

    if (skipFinishedAnime) {
      animes = animes
          .where((anime) => anime.getPlayStatus() != PlayStatus.finished)
          .toList();
      update();
    } else {
      // 恢复所有动漫
      animes = await AnimeDao.getAnimesInSource(sourceId: sourceWebsite.id);
    }

    completer = Completer();
    _startMigrate();
  }

  Future<void> _startMigrate() async {
    migrating = true;
    update();

    progressController.count = 0;
    progressController.total = animes.length;

    states.clear();
    for (final anime in animes) {
      states[anime.animeId] = DataState.data('等待中');
    }
    update();

    for (int i = 0; i < animes.length; i++) {
      if (completer?.isCompleted == true) {
        AppLog.info('迁移任务已取消');
        break;
      }
      final anime = animes[i];
      states[anime.animeId] = DataState.loading();
      update();

      if (ClimbAnimeUtil.getClimbWebsiteByAnimeUrl(anime.animeUrl) ==
          destWebsite) {
        // 动漫已经在目标搜索源时跳过迁移
        states[anime.animeId] = DataState.data('');
      } else {
        try {
          final newAnime = await _searchMatchedAnime(anime);
          if (newAnime == null) {
            states[anime.animeId] = DataState.data('未搜索到动漫');
          } else {
            await AnimeDao.updateAnime(anime, newAnime,
                updateCover: true,
                updateInfo: true,
                updateAnimeUrl: true,
                updateName: true);
            AppLog.info(
                '迁移动漫[${anime.animeId}]${anime.animeName}：${anime.animeUrl} -> ${newAnime.animeUrl}');
            animes[i] = newAnime.copyWith(
              animeId: anime.animeId, // 保持原有的animeId
            );
            states[anime.animeId] = DataState.data('');
          }
        } catch (e, st) {
          states[anime.animeId] =
              DataState.error(error: e, stackTrace: st, message: '迁移错误');
        }
        await Future.delayed(Duration(seconds: spacingSeconds));
      }

      update();
      progressController.count++;
    }

    migrating = false;
    update();
    if (completer?.isCompleted == false) {
      completer?.complete(true);
    }
  }

  Future<Anime?> _searchMatchedAnime(Anime anime) async {
    if (destWebsite == null) return null;

    final animes = await ClimbAnimeUtil.climbAnimesByKeywordAndWebSite(
        anime.animeName, destWebsite!);
    if (animes.isEmpty) return null;

    Anime? matchedAnime = animes.firstWhereOrNull((s) {
      // 首播时间一致则说明是同一部动漫，注意需要爬取动漫列表时就要获取到首播时间
      // 部分搜索源搜索只能获取到年份，因此时间不一致时再比较年份是否一致
      if (anime.premiereTime.isNotEmpty) {
        return s.premiereTime == anime.premiereTime ||
            anime.premiereTime.startsWith(s.premiereTime) ||
            s.premiereTime.startsWith(anime.premiereTime);
      } else {
        // 如果没有首播时间，则通过动漫名称进行精确匹配
        return s.animeName == anime.animeName ||
            s.nameAnother.contains(anime.animeName);
      }
    });
    // 最后如果还是没有匹配到，若搜索列表只有一个，则匹配该动漫
    if (matchedAnime == null && animes.length == 1) matchedAnime = animes.first;
    if (matchedAnime == null) return null;
    // 获取动漫详情
    return ClimbAnimeUtil.climbAnimeInfoByUrl(matchedAnime, showMessage: false);
  }

  void _cancelMigrate() {
    if (completer?.isCompleted == false) {
      completer?.complete(false);
    }
    migrating = false;
    update();
  }
}
