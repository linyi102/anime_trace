import 'package:flutter/material.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/utils/climb/site_collection_tab.dart';
import 'package:flutter_test_future/utils/climb/user_collection.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ImportCollectionController extends GetxController {
  String get tag => climbWebsite.name;

  ClimbWebsite climbWebsite;
  List<SiteCollectionTab> get siteCollectionTab =>
      climbWebsite.climb.siteCollectionTabs;
  List<RefreshController> refreshControllers = [];
  TextEditingController inputController = TextEditingController();
  TabController? tabController;

  String userId = "";
  List<UserCollection> userCollection = [];
  List<bool> searching = []; // 每个tab对应是否正在查询用户收藏

  bool showTip = true; // 最初主体显示使用提示，搜索后显示查询结果
  List<Anime> failedAnimes = [];

  Duration gap = const Duration(seconds: 5); // 每页获取间隔秒数

  /// 一键收藏状态
  bool quickCollecting = false; // 收藏时，不允许指定新的用户id、不允许切换搜索源、不允许在其他tab下点击一键收藏
  int curPage = 1;
  int totalPage = 1;
  int queryAnimeCnt = 0; // 已查询的数量
  int totalCnt = 0; // 应查询的总数
  int added = 0, // 数据库中已有
      addFail = 0, // 添加失败
      addOk = 0; // 添加成功
  bool stopQuickCollect = false;
  bool stopping = false;

  ImportCollectionController(this.climbWebsite) {
    for (int i = 0; i < siteCollectionTab.length; ++i) {
      searching.add(false);
      userCollection.add(UserCollection(totalCnt: 0, animes: []));
      refreshControllers.add(RefreshController());
    }
  }

  /// ids
  static String bottomBarId = "bottomBarId";
  static String bodyId = "bodyId";

  @override
  onClose() {
    // 关闭页面会调用onClose，因此这里不能销毁刷新控制器
    // for (var refreshController in refreshControllers) {
    //   refreshController.dispose();
    // }
  }

  resetQuickCollectStatus() {
    curPage = 1;
    totalPage = 1;
    queryAnimeCnt = 0;
    totalCnt = 0;
    added = 0;
    addFail = 0;
    addOk = 0;
    failedAnimes.clear();
    stopQuickCollect = false;
  }

  onEditingComplete() async {
    if (quickCollecting) {
      showToast("收藏中，请稍后再试");
      return;
    }

    userId = inputController.text;
    if (userId.isEmpty) {
      showToast("用户ID不能为空");
      return;
    }

    // 输入新用户，清除上次用户的添加状态
    resetQuickCollectStatus();
    // 隐藏提示
    showTip = false;
    // 有时查询有些慢，此时应该也显示加载圈
    for (int collIdx = 0; collIdx < siteCollectionTab.length; ++collIdx) {
      searching[collIdx] = true;
    }
    update([bodyId]);

    // 查询用户
    bool exist = await climbWebsite.climb.existUser(userId);

    if (!exist) {
      showToast("${climbWebsite.climb.sourceName}中不存在该用户");
      // 取消加载圈
      for (int collIdx = 0; collIdx < siteCollectionTab.length; ++collIdx) {
        searching[collIdx] = false;
      }
      update([bodyId]);
      return;
    }

    // 查询所有tab
    for (int i = 0; i < siteCollectionTab.length; ++i) {
      onRefresh(i);
    }
  }

  cancelQuickCollect(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确定停止收藏吗？"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
              onPressed: () {
                if (stopping) {
                  return;
                }
                Navigator.pop(context);
                stopQuickCollect = true;
                stopping = true;
                update([bottomBarId]);
              },
              child: const Text("确定")),
        ],
      ),
    );
  }

  quickCollect(BuildContext context, int collIdx, String tag) async {
    // 关闭底部面板
    Navigator.pop(context);
    Log.info("collIdx=$collIdx");

    resetQuickCollectStatus();
    quickCollecting = true;
    int pageSize = climbWebsite.climb.userCollPageSize;
    totalPage = _getPageCnt(userCollection[collIdx].totalCnt, pageSize);
    update([bottomBarId]);

    // 收藏该tab下的所有动漫
    while (!stopQuickCollect) {
      // 记录是否已爬取过该页
      bool existPageAnimes = false;
      List<Anime> pageAnimes = [];
      if (userCollection[collIdx].animes.length >= curPage * pageSize) {
        // 如果列表中已查询该页，则不再查询，且本次添加到数据库后不再延时
        existPageAnimes = true;
        pageAnimes = userCollection[collIdx]
            .animes
            .sublist((curPage - 1) * pageSize, curPage * pageSize);
      } else if (userCollection[collIdx].animes.length ==
          userCollection[collIdx].totalCnt) {
        // 如果已手动查询所有页，那么对于最后1页，不满足>=curPage * pageSize，因此这里需要额外处理
        if (curPage == totalPage) {
          existPageAnimes = true;
          pageAnimes =
              userCollection[collIdx].animes.sublist((curPage - 1) * pageSize);
        }
      }

      if (existPageAnimes) {
        Log.info("查询第$curPage页(已有，不再请求该页)");
      } else {
        Log.info("查询第$curPage页");
        pageAnimes = (await climbWebsite.climb.climbUserCollection(
          userId,
          siteCollectionTab[collIdx],
          page: curPage,
        ))
            .animes;
      }

      if (pageAnimes.isEmpty) {
        Log.info("查询数量为空，退出循环");
        break;
      }
      queryAnimeCnt += pageAnimes.length;

      bool skipDupNameAnime = SpProfile.getSkipDupNameAnime();
      // 每加载1页，就插入到数据库
      for (var anime in pageAnimes) {
        if ((await SqliteUtil.getAnimeByAnimeUrl(anime)).isCollected()) {
          added++;
        } else if (skipDupNameAnime &&
            (await AnimeDao.existAnimeName(anime.animeName))) {
          added++;
        } else {
          // 如果数据库不存在，则指定清单，然后添加到数据库
          anime.tagName = tag;
          anime.animeId = await SqliteUtil.insertAnime(anime);
          // 逐个添加到数据库
          if (anime.animeId > 0) {
            addOk++;
          } else {
            addFail++;
            failedAnimes.add(anime);
          }
        }
      }

      update([bottomBarId]);
      if (queryAnimeCnt >= userCollection[collIdx].totalCnt) {
        Log.info(
            "查询数量($queryAnimeCnt) >= 当前tab总数量(${userCollection[collIdx].totalCnt})，退出循环");
        break;
      }

      // 先重绘表示查询下一页
      if (curPage + 1 <= totalPage) {
        curPage++;
        update([bottomBarId]);
      } else {
        Log.info("要查询的页($curPage)>总页数($totalPage)，跳出循环");
        break;
      }
      // 如果该页查询了，那么需要等待一段时间再查询，避免频繁查询导致受限访问
      if (!existPageAnimes) await Future.delayed(gap);
    }

    if (stopQuickCollect) {
      // 如果取消了，则重绘底部栏
      update([bottomBarId]);
      // 恢复，避免下次无法收藏
      stopQuickCollect = false;
      stopping = false;
    }

    String msg = "";
    if (added > 0) msg += "$added个已跳过";
    if (addOk > 0) {
      if (msg.isNotEmpty) msg += "，";
      msg += "$addOk个添加成功";
    }
    if (addFail > 0) {
      if (msg.isNotEmpty) msg += "，";
      msg += "$addFail个添加失败";
    }
    showToast(msg);

    quickCollecting = false;
    update([bottomBarId]);
  }

  int _getPageCnt(int total, int pageSize) {
    int pageCnt;
    if (total % pageSize == 0) {
      pageCnt = total ~/ pageSize;
    } else {
      pageCnt = total ~/ pageSize + 1;
    }

    return pageCnt;
  }

  onRefresh(int collIdx) async {
    // 重置数据
    searching[collIdx] = true;
    userCollection[collIdx].animes.clear();
    userCollection[collIdx].totalCnt = 0;
    update([bodyId]);

    // 不放在setState是为了避免mounted为false时，不会赋值数据
    var collection = siteCollectionTab[collIdx];
    userCollection[collIdx] =
        await climbWebsite.climb.climbUserCollection(userId, collection);
    searching[collIdx] = false;
    update([bodyId]);

    // 如果当前数量不够总数，那么就重置为可以加载
    // 可能之前已全部加载或加载完毕，因此需要重置
    if (userCollection[collIdx].animes.length <
        userCollection[collIdx].totalCnt) {
      refreshControllers[collIdx].loadComplete();
    } else if (userCollection[collIdx].animes.length <=
        userCollection[collIdx].totalCnt) {
      refreshControllers[collIdx].loadNoData();
    }
  }

  Future<bool> loadMore(int collIdx) async {
    // 如果已查询的数量>=最大数量，则标记为没有更多数据了
    if (userCollection[collIdx].animes.length >=
        userCollection[collIdx].totalCnt) {
      refreshControllers[collIdx].loadNoData();
      return false;
    }

    // 每页x个，如果当前已查询了x个，那么x~/x=1，会再次查询第1页，因此最终要+1
    int page = (userCollection[collIdx].animes.length ~/
            climbWebsite.climb.userCollPageSize) +
        1;
    Log.info("查询第$page页");
    var newPageAnimes = (await climbWebsite.climb.climbUserCollection(
      userId,
      siteCollectionTab[collIdx],
      page: page,
    ))
        .animes;
    if (newPageAnimes.isNotEmpty) {
      // 添加新增的动漫，不要重新赋值userCollection
      userCollection[collIdx].animes.addAll(newPageAnimes);
      // 标记为获取完成，否则会一直显示加载，无法再次下拉加载更多
      refreshControllers[collIdx].loadComplete();
      update([bodyId]);
      return true;
    } else {
      // 如果为空，则说明加载失败
      refreshControllers[collIdx].loadFailed();
      return false;
    }
  }
}
