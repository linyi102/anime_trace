import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/climb_website.dart';
import 'package:flutter_test_future/classes/filter.dart';
import 'package:flutter_test_future/classes/update_record.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/climb_yhdm.dart';
import 'package:flutter_test_future/utils/dao/update_record_dao.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

class ClimbAnimeUtil {
  // 根据动漫网址中的关键字来判断来源
  static ClimbWebstie? getClimbWebsiteByAnimeUrl(String animeUrl) {
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
  }

  // 根据过滤查询目录动漫
  static Future<List<Anime>> climbDirectory(Filter filter) async {
    Climb climb = ClimbYhdm();
    List<Anime> directory = await climb.climbDirectory(filter);
    return directory;
  }

  // 多搜索源。根据关键字搜索动漫
  static Future<List<Anime>> climbAnimesByKeywordAndWebSite(
      String keyword, ClimbWebstie climbWebStie) async {
    List<Anime> climbAnimes = [];
    climbAnimes = await climbWebStie.climb.climbAnimesByKeyword(keyword);
    return climbAnimes;
  }

  // 进入该动漫网址，获取详细信息
  static Future<Anime> climbAnimeInfoByUrl(Anime anime,
      {bool showMessage = true}) async {
    if (anime.animeUrl.isEmpty) {
      debugPrint("无来源，无法更新，返回旧动漫对象");
      return anime;
    }
    Climb? climb = getClimbWebsiteByAnimeUrl(anime.animeUrl)?.climb;
    if (climb != null) {
      anime = await climb.climbAnimeInfo(anime, showMessage: showMessage);
    }
    return anime;
  }

  static bool canUpdateAllAnimesInfo = true;
  // 获取数据库中所有动漫，然后更新未完结的动漫信息
  static Future<bool> updateAllAnimesInfo() async {
    if (!canUpdateAllAnimesInfo) {
      showToast("刷新间隔为10s");
      return false;
    }

    canUpdateAllAnimesInfo = false;
    bool updateOk = false;
    Future.delayed(const Duration(seconds: 10))
        .then((value) => canUpdateAllAnimesInfo = true);

    showToast("更新动漫中...");
    int needUpdateCnt = 0, skipUpdateCnt = 0, updateOkCnt = 0;
    List<Anime> animes = await SqliteUtil.getAllAnimes();

    List<UpdateRecord> updateRecords = [];
    // 异步更新所有动漫信息
    for (var anime in animes) {
      // debugPrint("${anime.animeName}：${anime.playStatus}");
      // 跳过完结动漫
      if (anime.playStatus.contains("完结")) {
        skipUpdateCnt++;
        continue;
      }
      needUpdateCnt++;
      debugPrint("将要更新的第$needUpdateCnt个动漫：${anime.animeName}");
      // 要在爬取前赋值给oldAnime
      Anime oldAnime = Anime(
          animeId: anime.animeId,
          animeName: anime.animeName,
          animeEpisodeCnt: anime.animeEpisodeCnt,
          tagName: anime.tagName);
      // 爬取
      ClimbAnimeUtil.climbAnimeInfoByUrl(anime, showMessage: false)
          .then((value) {
        // 更新到数据库
        if (oldAnime.animeEpisodeCnt < anime.animeEpisodeCnt) {
          // 集数变化则记录到表中
          UpdateRecord updateRecord = UpdateRecord(
              animeId: anime.animeId,
              oldEpisodeCnt: oldAnime.animeEpisodeCnt,
              newEpisodeCnt: anime.animeEpisodeCnt,
              manualUpdateTime:
                  DateTime.now().toString().substring(0, 10) // 只存入年-月-日
              );
          // UpdateRecordDao.insert(updateRecord);
          updateRecords.add(updateRecord);
        }
        SqliteUtil.updateAnime(oldAnime, anime).then((value) {
          // 数据库更新完毕后计数，更新失败也会正常计数
          updateOkCnt++;
          debugPrint("updateOkCnt=$updateOkCnt");
          if (updateOkCnt == needUpdateCnt) {
            // 动漫全部更新完毕后，批量插入更新记录
            UpdateRecordDao.batchInsert(updateRecords).then((value) {
              updateOk = true;
              showToast("更新完毕");
              // 获取更新记录
              final UpdateRecordController updateRecordController = Get.find();
              // 在控制器中查询数据库，来更新数据
              updateRecordController.updateData();
            });
          }
        });
      });
    }

    debugPrint("共更新$needUpdateCnt个动漫，跳过了$skipUpdateCnt个动漫(完结)");
    return updateOk;
  }
}
