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
  static Future<List<Anime>> climbDirectory(AnimeFilter filter) async {
    Climb climb = ClimbYhdm();
    List<Anime> directory = await climb.climbDirectory(filter);
    return directory;
  }

  // 多搜索源。根据关键字搜索动漫
  static Future<List<Anime>> climbAnimesByKeywordAndWebSite(
      String keyword, ClimbWebsite climbWebStie) async {
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
    List<AnimeUpdateRecord> updateRecords = [];
    bool enableBatchInsertUpdateRecord =
        updateRecordController.enableBatchInsertUpdateRecord;

    // 异步更新所有动漫信息
    for (var anime in animes) {
      // debugPrint("${anime.animeName}：${anime.playStatus}");
      // 跳过完结动漫，还要豆瓣
      if (anime.playStatus.contains("完结") ||
          anime.animeUrl.contains("douban")) {
        skipUpdateCnt++;
        continue;
      }
      needUpdateCnt++;
      debugPrint("将要更新的第$needUpdateCnt个动漫：${anime.animeName}");
      // 要在爬取前赋值给oldAnime
      Anime oldAnime = anime.copy();
      // Anime oldAnime = Anime(
      //     animeId: anime.animeId,
      //     animeName: anime.animeName,
      //     animeEpisodeCnt: anime.animeEpisodeCnt,
      //     tagName: anime.tagName,
      //     playStatus: anime.playStatus,
      //   premiereTime: anime.premiereTime,
      //   animeUrl: anime.animeUrl
      // );
      AnimeUpdateRecord updateRecord = AnimeUpdateRecord(animeId: 0);
      // 爬取
      ClimbAnimeUtil.climbAnimeInfoByUrl(anime, showMessage: false)
          .then((value) {
        if (oldAnime.animeEpisodeCnt < anime.animeEpisodeCnt) {
          // 集数变化则记录到表中
          updateRecord = AnimeUpdateRecord(
              animeId: anime.animeId,
              oldEpisodeCnt: oldAnime.animeEpisodeCnt,
              newEpisodeCnt: anime.animeEpisodeCnt,
              manualUpdateTime:
                  DateTime.now().toString().substring(0, 10) // 只存入年-月-日
              );
          if (enableBatchInsertUpdateRecord) {
            updateRecords.add(updateRecord);
          } else {
            // 立即添加到数据库中
            UpdateRecordDao.batchInsert([updateRecord]);
          }
        }
        // 如果集数没变，仍然更新数据库中的动漫(可能封面等信息变化了)，只是不会添加到记录表中

        // 爬取完毕后，更新数据库中的动漫
        SqliteUtil.updateAnime(oldAnime, anime).then((value) {
          updateRecordController.incrementUpdateOkCnt();
          int updateOkCnt = updateRecordController.updateOkCnt.value;
          debugPrint("updateOkCnt=$updateOkCnt");
          if (enableBatchInsertUpdateRecord) {
            if (updateOkCnt == needUpdateCnt) {
              // 动漫全部更新完毕后，批量插入更新记录
              UpdateRecordDao.batchInsert(updateRecords).then((value) {
                debugPrint("更新完毕");
                // showToast("更新完毕");
                // 在控制器中查询数据库，来更新数据
                updateRecordController.updateData();
              });
            }
          } else {
            // 在控制器中单条插入查询数据库，来更新数据(有点糟糕，每次更新动漫都得重新查询更新记录表)
            // updateRecordController.updateData();
            // 直接添加到里面，注意需要按更新时间倒序排序，保证与重新查询出来的结果一致
            // 因为Vo里把animeId改为了anime，所以还转要Vo
            // BUG：尽管都添加到了controller里的数组，然鹅因为分页的缘故会自动请求数据库中更新记录表中的数据，导致被覆盖，而且此时数据库还没更新完毕，所以数据会不全
            if (oldAnime.animeEpisodeCnt < anime.animeEpisodeCnt) {
              // 只手动添加集数变大的更新记录
              updateRecordController.addUpdateRecord(updateRecord.toVo(anime));
            }
          }
        });
      }).catchError((obj, e) {
        if (enableBatchInsertUpdateRecord) {
          updateRecordController.incrementUpdateOkCnt();
          int updateOkCnt = updateRecordController.updateOkCnt.value;
          debugPrint("updateOkCnt=$updateOkCnt");

          if (updateOkCnt == needUpdateCnt) {
            // 动漫全部更新完毕后，批量插入更新记录
            UpdateRecordDao.batchInsert(updateRecords).then((value) {
              debugPrint("更新完毕");
              // showToast("更新完毕");
              // 在控制器中查询数据库，来更新数据
              updateRecordController.updateData();
            });
          }
        }
        // 爬取异常处理，因此不会有更新记录，所以不需要添加到数据库，不用处理else

        // 如果刚捕获到就打印，则不会执行上面的更新，所以放在这里
        // 捕获的错误大多是爬取动漫详细信息时数组越界的错误
        e.printError();
      });
    }
    // // 如果10秒后还是没能全部更新(可能是抛出了异常导致updateOkCnt不会自增)
    // // 则强制赋值为需要更新的数量，保证已有的更新记录插入到数据库中
    // Future.delayed(const Duration(seconds: 20)).then((value) {
    //   // 如果到了10s还在更新，此时超时，强制更新数量，那么之后还在更新时会在该基础上继续自增，导致updateOkCnt>needUpdateCnt
    //   // 尝试1：自增时如果超过了就-1(！这会导致后面自增后始终和need相等，就会重复添加)
    //   // 尝试2：不强制更新数量，直接批量插入就好了(尽管会卡在更新界面上)(！会导致重复添加数据)
    //   // 尝试3：延长时间
    //   // 尝试4：.catchError仍继续和比较
    //   // 不相等才强制更新，不然会插入两次
    //   if (updateRecordController.updateOkCnt.value !=
    //       updateRecordController.needUpdateCnt.value) {
    //     updateRecordController.forceUpdateOk(); // 保证强制更新完毕后退出更新界面
    //     // 因为ClimbAnimeUtil.climbAnimeInfoByUrl抛出异常，所以不会执行then，所以需要手动批量插入
    //     // 为什么不用.catchError？因为即使在里面自增了，也可能最后一个动漫爬取信息时也进入了这里，这样就只+1了，而不会判断是否更新完毕
    //     UpdateRecordDao.batchInsert(updateRecords).then((value) {
    //       debugPrint("更新完毕");
    //       // 在控制器中查询数据库，来更新数据
    //       updateRecordController.updateData();
    //     });
    //   }
    // });

    updateRecordController.setNeedUpdateCnt(needUpdateCnt);
    debugPrint("共更新$needUpdateCnt个动漫，跳过了$skipUpdateCnt个动漫(完结)");
    return true; // 返回true，之后会显示进度条对话框
  }
}
