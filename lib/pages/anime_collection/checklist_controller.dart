import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/params/anime_sort_cond.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:get/get.dart';

class ChecklistController extends GetxController {
  static ChecklistController get to => Get.find();

  List<String> tags = []; // 清单
  List<int> animeCntPerTag = []; // 各个清单下的动漫数量
  List<List<Anime>> animesInTag = []; // 各个清单下的动漫列表
  late List<int> pageIndexList;

  TabController? tabController;
  List<ScrollController> scrollControllers = [];

  AnimeSortCond animeSortCond = AnimeSortCond(
      specSortColumnIdx:
          SPUtil.getInt("AnimeSortCondSpecSortColumnIdx", defaultValue: 3),
      desc: SPUtil.getBool("AnimeSortCondDesc", defaultValue: true));

  // 数据加载
  bool loadOk = false;
  final int pageSize = 50;

  // 多选
  List<Anime> selectedAnimes = [];
  bool multi = false;

  void loadData(dynamic _animeListPageState) async {
    tags = await SqliteUtil.getAllTags();
    pageIndexList = List.generate(tags.length, (index) => 1); // 初始页都为1
    animesInTag = List.generate(tags.length, (index) => []);

    for (var sc in scrollControllers) {
      sc.dispose();
    }
    scrollControllers =
        List.generate(tags.length, (index) => ScrollController());

    int tabIdx = SPUtil.getInt("last_top_tab_index", defaultValue: 0);
    if (tabIdx <= 0 || tabIdx >= tags.length) tabIdx = 0;

    tabController?.dispose();
    // 顶部tab控制器
    tabController = TabController(
      initialIndex: tabIdx,
      length: tags.length,
      vsync: _animeListPageState,
    );
    // 添加监听器，记录最后一次的topTab的index
    tabController!.addListener(() {
      if (tabController!.index == tabController!.animation!.value) {
        // lastTopTabIndex = tabController.index;
        SPUtil.setInt("last_top_tab_index", tabController!.index);
        // 取消多选
        if (multi) {
          quitMulti();
        }
      }
    });

    loadAnimes();
  }

  /// 恢复数据后重新获取动漫
  /// TODO：没有获取并显示最新添加的清单，并且还能看见已删除的清单
  void restore() {
    loadAnimes();
  }

  void loadAnimes() async {
    // 首次或重新渲染时，重置页号，就能保证之后也能加载更多数据了
    for (int i = 0; i < pageIndexList.length; ++i) {
      pageIndexList[i] = 1;
    }

    Log.info("开始加载数据");
    animeCntPerTag = await SqliteUtil.getAnimeCntPerTag();
    for (int i = 0; i < tags.length; ++i) {
      animesInTag[i] = await SqliteUtil.getAllAnimeBytagName(
          tags[i], 0, pageSize,
          animeSortCond: animeSortCond);
      // Log.info("animesInTag[$i].length=${animesInTag[i].length}");
    }
    Log.info("数据加载完毕");
    loadOk = true;
    update();
    // 数据加载完毕后，再刷新页面。注意下面数据未加载完毕时，由于loadOk为false，显示的是其他页面
  }

  void quitMulti() {
    // 清空选择的动漫(注意在修改数量之后)，并消除多选状态
    multi = false;
    selectedAnimes.clear();
    update();
  }
}
