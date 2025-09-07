import 'package:animetrace/dao/anime_dao.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/climb_website.dart';
import 'package:animetrace/models/anime_update_record.dart';
import 'package:animetrace/controllers/update_record_controller.dart';
import 'package:animetrace/models/week_record.dart';
import 'package:animetrace/utils/climb/climb.dart';
import 'package:animetrace/dao/update_record_dao.dart';
import 'package:animetrace/utils/global_data.dart';
import 'package:get/get.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:animetrace/utils/log.dart';
import 'package:queue/queue.dart';

class ClimbAnimeUtil {
  /// 根据动漫网址获取搜索源
  static ClimbWebsite? getClimbWebsiteByAnimeUrl(String animeUrl) {
    for (var climbWebsite in climbWebsites) {
      // 先使用baseUrl来获取搜索源，避免用户自定义网址后无法根据regexp找到该搜索源
      if (animeUrl.startsWith(climbWebsite.climb.baseUrl) ||
          RegExp(climbWebsite.regexp).hasMatch(animeUrl)) {
        return climbWebsite;
      }
    }
    return null;
  }

  /// 获取视频链接
  static Future<String> getVideoUrl(String animeUrl, int episodeNumber) async {
    var climbWebsite = getClimbWebsiteByAnimeUrl(animeUrl);
    if (climbWebsite == null) {
      ToastUtil.showText('未知网站，无法获取播放链接');
      return '';
    }

    return climbWebsite.climb.getVideoUrl(animeUrl, episodeNumber);
  }

  /// 查询周表中某天的更新记录
  static Future<List<List<WeekRecord>>> climbWeeklyTable(
      ClimbWebsite climbWebsite) async {
    return climbWebsite.climb.climbWeeklyTable();
  }

  /// 多搜索源。根据关键字搜索动漫
  static Future<List<Anime>> climbAnimesByKeywordAndWebSite(
      String keyword, ClimbWebsite climbWebStie) async {
    List<Anime> climbAnimes = [];
    try {
      climbAnimes = await climbWebStie.climb
          .searchAnimeByKeyword(Uri.encodeComponent(keyword));
    } catch (e) {
      e.printError();
    }
    return climbAnimes;
  }

  /// collecting为false时，表示从动漫详细页下拉更新，通过动漫网址获取详细信息
  /// collecting为true时，表示第一次收藏，此时需要爬取动漫网址来获取更全的信息(age和樱花跳过)
  static Future<Anime> climbAnimeInfoByUrl(Anime anime,
      {bool showMessage = true}) async {
    if (anime.animeUrl.isEmpty) {
      AppLog.info("无来源，无法更新，返回旧动漫对象");
      return anime;
    }
    Climb? climb = getClimbWebsiteByAnimeUrl(anime.animeUrl)?.climb;
    if (climb == null) return anime;

    // 使用最新的搜索源网址进行爬取
    anime.animeUrl = anime.animeUrl.replaceFirst(
        RegExp(r'https{0,1}:\/\/.+?\/'),
        climb.baseUrl.endsWith('/') ? climb.baseUrl : '${climb.baseUrl}/');
    try {
      // 如果爬取时缺少element导致越界，此处会捕获到异常，保证正常进行
      anime = await climb.climbAnimeInfo(anime);
      anime.animeEpisodeCnt = _adjustEpisodeCntByEpisdoeStartNumber(
          anime.animeEpisodeCnt, anime.episodeStartNumber);
      if (showMessage) ToastUtil.showText("更新完毕");
    } catch (err, stack) {
      AppLog.error('获取动漫详情失败。动漫名：${anime.animeName}，网址：${anime.animeUrl}',
          error: err, stackTrace: stack);
    }
    return anime;
  }

  static bool canUpdateAllAnimesInfo = true;

  /// 获取数据库中所有动漫，然后更新未完结的动漫信息
  static void updateAllAnimesInfo() async {
    if (!canUpdateAllAnimesInfo) {
      ToastUtil.showText("更新间隔为10s，请稍后再试");
      return;
    }

    // ToastUtil.showText("全局更新中");
    canUpdateAllAnimesInfo = false;
    Future.delayed(const Duration(seconds: 10))
        .then((value) => canUpdateAllAnimesInfo = true);

    int skipUpdateCnt = 0, needUpdateCnt = 0;
    final UpdateRecordController updateRecordController = Get.find();
    updateRecordController.resetUpdateOkCnt(); // 重新设置
    updateRecordController.updating.value = true;

    List<Anime> needUpdateAnimes = await AnimeDao.getAllNeedUpdateAnimes();

    final queue = Queue(delay: const Duration(seconds: 1), parallel: 5);
    // 异步更新所有动漫信息
    for (var anime in needUpdateAnimes) {
      needUpdateCnt++;
      AppLog.info("将要更新的第$needUpdateCnt个动漫：${anime.animeName}");
      // 要在爬取前赋值给oldAnime
      Anime oldAnime = anime.copyWith();
      // 爬取
      queue.add(
        () => ClimbAnimeUtil.climbAnimeInfoByUrl(anime, showMessage: false)
            .then((_) {
          // 集数变化则记录到表中
          _addUpdateRecord(oldAnime, anime);

          // 如果集数没变，仍然更新数据库中的动漫(可能封面等信息变化了)，只是不会添加到记录表中
          // 爬取完毕后，更新数据库中的动漫
          AnimeDao.updateAnime(oldAnime, anime).then((value) {
            // 之所以不采用批量插入，是担心因某个动漫爬取出错导致始终无法全部更新
            updateRecordController.incrementUpdateOkCnt();
            int updateOkCnt = updateRecordController.updateOkCnt.value;
            AppLog.info("updateOkCnt=$updateOkCnt");
          });
        }),
      );
    }

    updateRecordController.setNeedUpdateCnt(needUpdateCnt);
    AppLog.info("共需更新$needUpdateCnt个动漫，跳过了$skipUpdateCnt个动漫(完结)");
    if (needUpdateCnt > 0) await queue.onComplete;
    updateRecordController.updating.value = false;
    ToastUtil.showText("全局更新完毕");
  }

  static void _addUpdateRecord(Anime oldAnime, Anime anime) {
    if (oldAnime.animeEpisodeCnt < anime.animeEpisodeCnt) {
      final updateRecord = AnimeUpdateRecord(
          animeId: anime.animeId,
          oldEpisodeCnt: oldAnime.animeEpisodeCnt,
          newEpisodeCnt: anime.animeEpisodeCnt,
          manualUpdateTime: DateTime.now().toString()); // 存放详细时间，目的保证最后更新记录在最前面
      // 只有集数变化才插入更新表
      UpdateRecordDao.insert(updateRecord).then((newId) {
        updateRecord.id = newId;
        // 获取到id后再添加，避免新增的删除失败
        UpdateRecordController.to.addUpdateRecord(updateRecord.toVo(anime));
      });
    }
  }

  /// 调整获取到的总集数
  /// 如果爬取到总集数为20集，但是设置的起始集为12，那么总集数应该为20-12+1=9
  static int _adjustEpisodeCntByEpisdoeStartNumber(
      int episodeCnt, int episodeStartNumber) {
    return episodeCnt - episodeStartNumber + 1;
  }
}
