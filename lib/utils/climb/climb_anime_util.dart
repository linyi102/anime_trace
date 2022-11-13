import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/models/anime_update_record.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/climb_yhdm.dart';
import 'package:flutter_test_future/dao/update_record_dao.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

import '../../models/params/page_params.dart';

class ClimbAnimeUtil {
  // 根据动漫网址中的关键字来判断来源
  static ClimbWebsite? getClimbWebsiteByAnimeUrl(String animeUrl) {
    for (var climbWebsite in climbWebsites) {
      // 存在animeUrl以https://www.agemys.cc/和https://www.agemys.com/开头的，因此都需要解释为age动漫源
      // 因此采用contain keyword，而不是startWith baseUrl
      // if (animeUrl.startsWith(climbWebsite.baseUrl)) {
      //   return climbWebsite;
      // }
      if (animeUrl.contains(climbWebsite.keyword)) {
        return climbWebsite;
      }
    }
    return null;
  }

  // 根据过滤查询目录动漫
  static Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) async {
    Climb climb = ClimbYhdm();
    List<Anime> directory = await climb.climbDirectory(filter, pageParams);
    return directory;
  }

  // 多搜索源。根据关键字搜索动漫
  static Future<List<Anime>> climbAnimesByKeywordAndWebSite(
      String keyword, ClimbWebsite climbWebStie) async {
    List<Anime> climbAnimes = [];
    try {
      climbAnimes = await climbWebStie.climb.climbAnimesByKeyword(keyword);
    } catch (e) {
      e.printError();
    }
    return climbAnimes;
  }

  // collecting为false时，表示从动漫详细页下拉更新，通过动漫网址获取详细信息
  // collecting为true时，表示第一次收藏，此时需要爬取动漫网址来获取更全的信息(age和樱花跳过)
  static Future<Anime> climbAnimeInfoByUrl(Anime anime,
      {bool showMessage = true}) async {
    if (anime.animeUrl.isEmpty) {
      debugPrint("无来源，无法更新，返回旧动漫对象");
      return anime;
    }
    Climb? climb = getClimbWebsiteByAnimeUrl(anime.animeUrl)?.climb;
    if (climb != null) {
      try {
        // 如果爬取时缺少element导致越界，此处会捕获到异常，保证正常进行
        anime = await climb.climbAnimeInfo(anime, showMessage: showMessage);
      } catch (e) {
        e.printError();
      }
    }
    return anime;
  }

  static bool canUpdateAllAnimesInfo = true;

  // 获取数据库中所有动漫，然后更新未完结的动漫信息
  static Future<bool> updateAllAnimesInfo() async {
    if (!canUpdateAllAnimesInfo) {
      showToast("更新间隔为10s");
      return false;
    }

    canUpdateAllAnimesInfo = false;
    Future.delayed(const Duration(seconds: 10))
        .then((value) => canUpdateAllAnimesInfo = true);

    // showToast("更新动漫中...");
    // int needUpdateCnt = 0, skipUpdateCnt = 0, updateOkCnt = 0;
    int skipUpdateCnt = 0, needUpdateCnt = 0;
    final UpdateRecordController updateRecordController = Get.find();
    updateRecordController.resetUpdateOkCnt(); // 重新设置

    List<Anime> animes = await SqliteUtil.getAllAnimes();

    // 异步更新所有动漫信息
    for (var anime in animes) {
      // debugPrint("${anime.animeName}：${anime.playStatus}");
      // 跳过完结动漫，还要豆瓣
      // 不能只更新连载中动漫，因为有些未播放，后面需要更新后才会变成连载
      if (anime.playStatus.contains("完结") ||
          anime.animeUrl.contains("douban")) {
        skipUpdateCnt++;
        continue;
      }
      needUpdateCnt++;
      debugPrint("将要更新的第$needUpdateCnt个动漫：${anime.animeName}");
      // 要在爬取前赋值给oldAnime
      Anime oldAnime = anime.copyWith();
      AnimeUpdateRecord updateRecord = AnimeUpdateRecord(animeId: 0);
      // 爬取
      ClimbAnimeUtil.climbAnimeInfoByUrl(anime, showMessage: false)
          .then((value) {
        // 集数变化则记录到表中
        if (oldAnime.animeEpisodeCnt < anime.animeEpisodeCnt) {
          updateRecord = AnimeUpdateRecord(
              animeId: anime.animeId,
              oldEpisodeCnt: oldAnime.animeEpisodeCnt,
              newEpisodeCnt: anime.animeEpisodeCnt,
              manualUpdateTime:
                  DateTime.now().toString()); // 存放详细时间，目的保证最后更新记录在最前面
          updateRecordController.addUpdateRecord(updateRecord.toVo(anime));
          // 只有集数变化才插入更新表
          UpdateRecordDao.insert(updateRecord);
        }
        // 如果集数没变，仍然更新数据库中的动漫(可能封面等信息变化了)，只是不会添加到记录表中

        // 爬取完毕后，更新数据库中的动漫
        SqliteUtil.updateAnime(oldAnime, anime).then((value) {
          // 之所以不采用批量插入，是担心因某个动漫爬取出错导致始终无法全部更新
          updateRecordController.incrementUpdateOkCnt();
          int updateOkCnt = updateRecordController.updateOkCnt.value;
          debugPrint("updateOkCnt=$updateOkCnt");
        });
      });
    }

    updateRecordController.setNeedUpdateCnt(needUpdateCnt);
    debugPrint("共更新$needUpdateCnt个动漫，跳过了$skipUpdateCnt个动漫(完结)");
    return true; // 返回true，之后会显示进度条对话框
  }
}
