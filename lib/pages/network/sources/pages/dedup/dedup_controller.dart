import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:get/get.dart';

class DedupController extends GetxController {
  Map<String, List<Anime>> animeMap = {};
  List<String> nameList = [];
  int totalCnt = 0;
  Set<int> selectedIds = {};
  bool initOk = false;

  bool enableRetainAnimeHasProgress = false;

  static String bodyId = "bodyId";
  static String appBarId = "appBarId";

  @override
  void onInit() {
    _initData();
    super.onInit();
  }

  Future<void> refreshData() async {
    animeMap.clear();
    nameList.clear();
    totalCnt = 0;
    return _initData();
  }

  Future<void> _initData() async {
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
    initOk = true;
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
              // 如果移除后，key对应的value列表为空，那么就移除掉这个key
              if (animeMap[key]!.isEmpty) {
                animeMap.remove(key);
                // 还要从名字列表中移除
                nameList.removeWhere((element) => element == anime.animeName);
              }
            }

            break;
          }
        }
        if (find) break;
      }
      // 总数-1
      totalCnt--;
    }

    // 退出多选
    clearSelected();
  }
}
