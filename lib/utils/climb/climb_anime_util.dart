import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/models/anime_update_record.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/models/week_record.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/dao/update_record_dao.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:get/get.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/utils/log.dart';

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
  static Future<List<WeekRecord>> climbWeekRecords(
      ClimbWebsite climbWebsite, int weekday) async {
    if (weekday <= 0 && weekday > 7) {
      Log.info("非法weekday: $weekday");
      return [];
    }
    return climbWebsite.climb.climbWeeklyTable(weekday);
  }

  /// 多搜索源。根据关键字搜索动漫
  static Future<List<Anime>> climbAnimesByKeywordAndWebSite(
      String keyword, ClimbWebsite climbWebStie) async {
    List<Anime> climbAnimes = [];
    try {
      climbAnimes = await climbWebStie.climb.searchAnimeByKeyword(keyword);
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
      Log.info("无来源，无法更新，返回旧动漫对象");
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
      anime = await climb.climbAnimeInfo(anime, showMessage: showMessage);
      anime.animeEpisodeCnt = _adjustEpisodeCntByEpisdoeStartNumber(
          anime.animeEpisodeCnt, anime.episodeStartNumber);
    } catch (e) {
      e.printError();
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

    List<Future> futures = [];
    // 异步更新所有动漫信息
    for (var anime in needUpdateAnimes) {
      needUpdateCnt++;
      Log.info("将要更新的第$needUpdateCnt个动漫：${anime.animeName}");
      // 要在爬取前赋值给oldAnime
      Anime oldAnime = anime.copyWith();
      AnimeUpdateRecord updateRecord = AnimeUpdateRecord(animeId: 0);
      // 爬取
      futures.add(ClimbAnimeUtil.climbAnimeInfoByUrl(anime, showMessage: false)
          .then((value) {
        // 集数变化则记录到表中
        if (oldAnime.animeEpisodeCnt < anime.animeEpisodeCnt) {
          updateRecord = AnimeUpdateRecord(
              animeId: anime.animeId,
              oldEpisodeCnt: oldAnime.animeEpisodeCnt,
              newEpisodeCnt: anime.animeEpisodeCnt,
              manualUpdateTime:
                  DateTime.now().toString()); // 存放详细时间，目的保证最后更新记录在最前面
          // 只有集数变化才插入更新表
          UpdateRecordDao.insert(updateRecord).then((newId) {
            updateRecord.id = newId;
            // 获取到id后再添加，避免新增的删除失败
            updateRecordController.addUpdateRecord(updateRecord.toVo(anime));
          });
        }
        // 如果集数没变，仍然更新数据库中的动漫(可能封面等信息变化了)，只是不会添加到记录表中

        // 爬取完毕后，更新数据库中的动漫
        AnimeDao.updateAnime(oldAnime, anime).then((value) {
          // 之所以不采用批量插入，是担心因某个动漫爬取出错导致始终无法全部更新
          updateRecordController.incrementUpdateOkCnt();
          int updateOkCnt = updateRecordController.updateOkCnt.value;
          Log.info("updateOkCnt=$updateOkCnt");
        });
      }));
    }

    updateRecordController.setNeedUpdateCnt(needUpdateCnt);
    Log.info("共需更新$needUpdateCnt个动漫，跳过了$skipUpdateCnt个动漫(完结)");
    await Future.wait(futures);
    await 400.milliseconds.delay();
    updateRecordController.updating.value = false;
    ToastUtil.showText("全局更新完毕");
  }

  /// 调整获取到的总集数
  /// 如果爬取到总集数为20集，但是设置的起始集为12，那么总集数应该为20-12+1=9
  static int _adjustEpisodeCntByEpisdoeStartNumber(
      int episodeCnt, int episodeStartNumber) {
    return episodeCnt - episodeStartNumber + 1;
  }
}
