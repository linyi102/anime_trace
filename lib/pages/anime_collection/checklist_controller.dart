
import 'package:flutter/material.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/params/anime_sort_cond.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/platform.dart';
import 'package:animetrace/utils/sp_util.dart';
import 'package:animetrace/utils/sqlite_util.dart';
import 'package:get/get.dart';

class ChecklistController extends GetxController
    with GetTickerProviderStateMixin {
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
  bool firstLoading = true;
  int get pageSize => 50;

  // 多选
  List<Anime> selectedAnimes = [];
  bool multi = false;

  init() async {
    // 不要放在loadData中，因为要保证收藏页在initState中loadData执行完毕
    // 否则会导致修改清单数量后，和上次的animesInTag和animeCntPerTag不匹配。
    tags = await SqliteUtil.getAllTags();
  }

  void loadData() {
    if (firstLoading) {
      firstLoading = false;
    }
    pageIndexList = List.generate(tags.length, (index) => 1); // 初始页都为1
    // animesInTag = List.generate(tags.length, (index) => []);
    // 不要清空animes，而是根据清单数量增加[]或移除
    // 尽管当前可能不匹配(清单排序)，但并不影响，可以先显示出来，后面会再加载
    while (animesInTag.length > tags.length) {
      animesInTag.removeLast();
    }
    while (animesInTag.length < tags.length) {
      animesInTag.add([]);
    }
    while (animeCntPerTag.length > tags.length) {
      animeCntPerTag.removeLast();
    }
    while (animeCntPerTag.length < tags.length) {
      animeCntPerTag.add(0);
    }

    for (var sc in scrollControllers) {
      sc.dispose();
    }
    scrollControllers =
        List.generate(tags.length, (index) => ScrollController());

    int tabIdx = SPUtil.getInt("last_top_tab_index", defaultValue: 0);
    if (tabIdx <= 0 || tabIdx >= tags.length) tabIdx = 0;

    tabController?.removeListener(_tabIdxlistener);
    tabController?.dispose();
    tabController = TabController(
        initialIndex: tabIdx,
        length: tags.length,
        vsync: this,
        animationDuration: PlatformUtil.tabControllerAnimationDuration);
    // 添加监听器，记录最后一次的topTab的index
    tabController!.addListener(_tabIdxlistener);

    loadAnimes();
  }

  _tabIdxlistener() {
    if (tabController!.index == tabController!.animation!.value) {
      // lastTopTabIndex = tabController.index;
      SPUtil.setInt("last_top_tab_index", tabController!.index);
      // 取消多选
      if (multi) {
        quitMulti();
      }
    }
  }

  /// 恢复数据后重新加载
  void restore() async {
    tags = await SqliteUtil.getAllTags();
    loadData();
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

  /// 生成描述
  String get desc {
    String res = "";
    for (int i = 0; i < tags.length; ++i) {
      res += tags[i];
      if (i < animeCntPerTag.length) res += "(${animeCntPerTag[i]})";
      if (i + 1 < tags.length) res += " ";
    }
    return res;
  }
}
