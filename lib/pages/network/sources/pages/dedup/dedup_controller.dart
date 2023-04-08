import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:get/get.dart';

class DedupController extends GetxController {
  Map<String, List<Anime>> animeMap = {};
  List<String> nameList = [];
  int totalCnt = 0;
  Set<int> selectedIds = {};
  bool loading = false;

  bool enableRetainAnimeHasProgress = false;

  static String bodyId = "bodyId";
  static String appBarId = "appBarId";

  @override
  void onInit() {
    _initData(showLoading: true);
    super.onInit();
  }

  Future<void> refreshData({bool showLoading = false}) async {
    animeMap.clear();
    nameList.clear();
    totalCnt = 0;
    return _initData(showLoading: showLoading);
  }

  Future<void> _initData({bool showLoading = false}) async {
    if (showLoading) {
      loading = true;
      update([bodyId, appBarId]);
    }
    // 显示加载圈后，等待一段时间再去查询，避免执行页面切换动画时卡顿
    await Future.delayed(const Duration(milliseconds: 200));

    var animes = await AnimeDao.getDupAnimes();
    for (var anime in animes) {
      if (animeMap.containsKey(anime.animeName)) {
        animeMap[anime.animeName]!.add(anime);
      } else {
        animeMap[anime.animeName] = [anime];
        nameList.add(anime.animeName);
      }
    }
    totalCnt = animes.length;
    loading = false;
    update([bodyId, appBarId]);
  }

  /// 反选指定id的动漫
  invertSelectId(int id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
    update([bodyId, appBarId]);
  }

  /// 保留有进度的动漫
  retainAnimeHasProgress() {
    animeMap.forEach((key, value) {
      for (var anime in value) {
        if (anime.checkedEpisodeCnt == 0) {
          selectedIds.add(anime.animeId);
        }
      }
    });

    update([bodyId, appBarId]);
  }

  /// 清空选择
  clearSelected() {
    selectedIds.clear();
    update([bodyId, appBarId]);
  }

  /// 删除选中的动漫
  deleteSelectedAnimes() async {
    for (var id in selectedIds) {
      // 从数据库中移除
      await AnimeDao.deleteAnimeByAnimeId(id);
      // 从map中移除
      bool find = false;
      var iterable = animeMap.values;
      for (var animes in iterable) {
        for (var anime in animes) {
          if (anime.animeId == id) {
            find = true;

            var key = anime.animeName;
            // 如果移除前改名了，那么没有animeName这个key，因此这里需要判断
            if (animeMap.containsKey(key)) {
              animeMap[key]!.removeWhere((element) => element.animeId == id);
              totalCnt--;

              var remainCnt = animeMap[key]!.length;
              // 如果删除后，key对应的value列表为空或只剩1个，那么就移除掉这个key
              // 若只剩1个，不要移除该key，起初是想让用户避免删除后剩1个却仍显示的干扰，但如果移除了可能会让用户认为误删
              // if (remainCnt == 0 || remainCnt == 1) {
              if (remainCnt == 0) {
                animeMap.remove(key);
                totalCnt -= remainCnt;
                // 还要从名字列表中移除
                nameList.removeWhere((element) => element == anime.animeName);
              }
            }

            break;
          }
        }
        if (find) break;
      }
    }

    // 退出多选
    clearSelected();
  }
}
