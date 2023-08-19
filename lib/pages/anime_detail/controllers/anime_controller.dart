import 'package:flutter/material.dart';
import 'package:flutter_test_future/dao/anime_label_dao.dart';
import 'package:flutter_test_future/dao/episode_desc_dao.dart';
import 'package:flutter_test_future/dao/note_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/episode.dart';
import 'package:flutter_test_future/models/label.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:get/get.dart';

class AnimeController extends GetxController {
  /////////////////////////////// 数据 ///////////////////////////////
  var anime = Anime(animeName: "", animeEpisodeCnt: 0);
  bool get isCollected => anime.isCollected();
  bool loadingAnime = false;

  String tag;
  AnimeController(this.tag);

  /// 集、笔记
  List<Episode> episodes = [];
  var loadEpisodeOk = false;

  // 多选
  Map<int, bool> mapSelected = {};
  var multiSelected = false.obs; // 集长按，修改该值为true，详细页监测要为true，显示底部操作栏。所以使用obs
  int lastMultiSelectedIndex = -1; // 记住最后一次多选的集下标

  // 选择显示的集范围
  int currentStartEpisodeNumber = 1;
  final int episodeRangeSize = 50;

  // 显示简介
  var showDescInAnimeDetailPage = SpProfile.getShowDescInAnimeDetailPage().obs;

  // 标签
  var labels = <Label>[].obs;

  // 评价数量
  var rateNoteCount = 0;

  /////////////////////////////// ids ///////////////////////////////

  static const String prefix = "getbuilder-anime-detail-page";
  String detailPageId = "$prefix-detailPage";
  String infoId = "$prefix-info";
  String appbarId = "$prefix-appbar";
  String episodeId = "$prefix-episode";
  String infoPageId = "$prefix-info-page";
  String coverId = "$prefix-cover-page";
  String rateNoteCountId = "$prefix-rateNoteCount";

  /////////////////////////////// 方法 ///////////////////////////////

  @override
  void dispose() {
    anime = Anime(animeName: "", animeEpisodeCnt: 0);
    popPage();
    super.dispose();
  }

  void popPage() {
    episodes.clear();
    labels.clear();
    mapSelected.clear();
    multiSelected.value = false;
    rateNoteCount = 0;
  }

  // 取消收藏时需要重置动漫：清空集信息、笔记、标签等等
  // 不要在退出详情页时使用重置，因为pop后返回的_anime也是这个对象，如果重置会导致收藏页进入详情页再返回后移除收藏列表
  void resetAnime() {
    // 只删除固定信息，保留其他信息
    anime.animeId = 0;
    anime.checkedEpisodeCnt = 0;
    anime.tagName = "";

    episodes.clear();
    loadEpisodeOk = false;

    labels.clear();
    mapSelected.clear();

    // 重绘appbar(隐藏更多按钮)、重绘信息行(右侧显示收藏按钮)、重绘集(不显示集信息)
    update([appbarId, infoId, episodeId]);
  }

  reloadAnime(Anime anime) {
    // 可能在搜索内部添加该动漫了，因此需要重新获取动漫信息
    loadAnime(anime);
    // 还有重新获取集信息
    loadEpisode();
  }

  void loadAnime(Anime newAnime) async {
    loadingAnime = true;
    // 重绘整个详情页，显示加载圈，避免显示上一个动漫的信息或者显示空动漫(可能会点击收藏按钮)
    update([detailPageId]);

    bool existDbAnime = false;
    // 从数据库中获取动漫
    Anime dbAnime = await SqliteUtil.getAnimeByAnimeId(newAnime.animeId);
    // 如果收藏了，则更新为完整的动漫信息
    if (dbAnime.isCollected()) {
      // 数据库中存在该id动漫
      existDbAnime = true;
    } else {
      // 如果根据id找不到，则尝试查询动漫网址
      dbAnime = await SqliteUtil.getAnimeByAnimeUrl(
          newAnime); // 要传入widget.anime，而不是dbAnime(因为dbAnime没找到)
      if (dbAnime.isCollected()) {
        existDbAnime = true;
      }
    }

    // await Future.delayed(const Duration(seconds: 2));
    if (existDbAnime) {
      Log.info("数据库中存在动漫：${dbAnime.animeId}, ${dbAnime.animeName}");
      // 最新动漫指向数据库动漫
      newAnime = dbAnime;
    }
    // 控制器中的anime指向最新动漫
    anime = newAnime;
    loadLabels(); // labels由obs变化，所有要手动获取最新标签

    // 重绘整个详情页
    loadingAnime = false;
    update([detailPageId]);
  }

  void updateAnime(Anime newAnime) {
    anime = newAnime;
    update([appbarId, infoId]);
  }

  void updateAnimeInfo() {
    // 因为信息有很多个，所以在外面更改控制器中的anime后，调用该方法去重绘
    update([infoId, infoPageId]);
  }

  void updateCoverUrl(String url) {
    anime.animeCoverUrl = url;
    update([coverId]);
  }

  // 获取评价数量
  void loadRateNoteCount() async {
    if (isCollected) {
      rateNoteCount = await NoteDao.getRateNoteCountByAnimeId(anime.animeId);
    }
    update([rateNoteCountId]);
  }

  // 获取添加的标签
  void loadLabels() async {
    labels.clear();
    if (isCollected) {
      Log.info("查询当前动漫(id=${anime.animeId})的所有标签");
      labels.addAll(await AnimeLabelDao.getLabelsByAnimeId(anime.animeId));
    }
  }

  // 退出多选模式
  void quitMultiSelectionMode() {
    // 清空选中
    mapSelected.clear();
    // 隐藏多选操作栏
    multiSelected.value = false;
    // 重绘集页面
    update([episodeId]);
  }

  void turnShowDescInAnimeDetailPage() {
    showDescInAnimeDetailPage.value = !showDescInAnimeDetailPage.value;
    SpProfile.turnShowDescInAnimeDetailPage();
  }

  void loadEpisode() async {
    // 重置，然后重新渲染
    loadEpisodeOk = false;
    episodes.clear();
    update([episodeId]);

    // 加载集信息
    // 一定要延时，否则修改集范围后，前面集不会重绘导致没有加载笔记
    // 首次进入动漫详情页也要延迟，是为了避免页面切换动画卡顿
    await Future.delayed(const Duration(milliseconds: 200));

    // await Future.delayed(const Duration(seconds: 4));
    if (anime.animeEpisodeCnt == 0) {
      // 如果为0，则不修改currentStartEpisodeNumber
    } else if (currentStartEpisodeNumber > anime.animeEpisodeCnt) {
      // 起始集编号>动漫集数，则从最后一个范围开始x
      // 修改后集数为260，则(260/50)=5.2=5, 5*50=250, 250+1=251
      // 修改后集数为250，则(250/50)=5，(5-1)*50=200, 200+1=201，也就是251-50
      currentStartEpisodeNumber =
          anime.animeEpisodeCnt ~/ episodeRangeSize * episodeRangeSize + 1;
      if (anime.animeEpisodeCnt % episodeRangeSize == 0) {
        currentStartEpisodeNumber -= episodeRangeSize;
      }
    }

    // 范围：[start, end]
    int end = currentStartEpisodeNumber + episodeRangeSize - 1;
    if (end > anime.animeEpisodeCnt) {
      end = anime.animeEpisodeCnt;
    }
    episodes = await SqliteUtil.getEpisodeHistoryByAnimeIdAndRange(
        anime, currentStartEpisodeNumber, end);

    _sortEpisodes(SPUtil.getString("episodeSortMethod",
        defaultValue: sortMethods[0])); // 排序，默认升序，兼容旧版本

    List<EpisodeDesc> descs = await EpisodeDescDao.queryAll(anime.animeId);

    for (var desc in descs) {
      int idx = episodes.indexWhere((element) => element.number == desc.number);
      if (idx >= 0) {
        episodes[idx].desc = desc;
      }
    }

    loadEpisodeOk = true;
    update([episodeId]);
  }

  // 多选后，选择日期，并更新数据库
  // 尾部的选择日期按钮也可以使用该方法，记得提前加入到多选中
  Future<void> pickDateForEpisodes({required BuildContext context}) async {
    DateTime defaultDateTime = DateTime.now();
    String dateTime = await _showDatePicker(
        context: context, defaultDateTime: defaultDateTime);
    if (dateTime.isEmpty) return;

    // 遍历选中的下标
    mapSelected.forEach((episodeIndex, value) {
      int episodeNumber = episodes[episodeIndex].number;
      if (episodes[episodeIndex].isChecked()) {
        SqliteUtil.updateHistoryItem(
            anime.animeId, episodeNumber, dateTime, anime.reviewNumber);
      } else {
        SqliteUtil.insertHistoryItem(
            anime.animeId, episodeNumber, dateTime, anime.reviewNumber);
      }
      episodes[episodeIndex].dateTime = dateTime;
    });
  }

  Future<String> _showDatePicker(
      {required BuildContext context, DateTime? defaultDateTime}) async {
    DateTime? datePicker = await showDatePicker(
      context: context,
      initialDate: defaultDateTime ?? DateTime.now(),
      // 没有给默认时间时，设置为今天
      firstDate: DateTime(1970),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    // 如果没有选择日期，则直接返回
    if (datePicker == null) return "";
    TimeOfDay? timePicker = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    // 同理
    if (timePicker == null) return "";
    return DateTime(datePicker.year, datePicker.month, datePicker.day,
            timePicker.hour, timePicker.minute)
        .toString();
  }

  //  其他页面(例如详情页修改了动漫封面)更新动漫时，动漫详细页可以收到通知并重新渲染

  /////////////////////////////// 排序 ///////////////////////////////

  List<String> sortMethods = [
    "sortByEpisodeNumberAsc",
    "sortByEpisodeNumberDesc",
    "sortByUnCheckedFront"
  ];

  List<String> sortMethodsName = ["集数升序", "集数倒序", "未完成在前"];

  void dialogSelectSortMethod(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('排序方式'),
          content: buildSortPage(),
        );
      },
    );
  }

  Widget buildSortPage() {
    return StatefulBuilder(
      builder: (context, setState) {
        List<Widget> radioList = [];
        for (int i = 0; i < sortMethods.length; ++i) {
          radioList.add(
            ListTile(
              title: Text(sortMethodsName[i]),
              leading: sortMethods[i] == SPUtil.getString("episodeSortMethod")
                  ? Icon(Icons.radio_button_on_outlined,
                      color: Theme.of(context).primaryColor)
                  : const Icon(Icons.radio_button_off_outlined),
              onTap: () {
                Log.info("修改排序方式为${sortMethods[i]}");
                _sortEpisodes(sortMethods[i]);
                // 重绘
                update([episodeId]);
                // 修改单选状态
                setState(() {});
              },
            ),
          );
        }

        return SingleChildScrollView(child: Column(children: radioList));
      },
    );
  }

  void _sortEpisodes(String sortMethod) {
    if (sortMethod == "sortByEpisodeNumberAsc") {
      _sortByEpisodeNumberAsc();
    } else if (sortMethod == "sortByEpisodeNumberDesc") {
      _sortByEpisodeNumberDesc();
    } else if (sortMethod == "sortByUnCheckedFront") {
      _sortByUnCheckedFront();
    } else {
      throw "不可能的排序方式";
    }
    SPUtil.setString("episodeSortMethod", sortMethod);
  }

  void _sortByEpisodeNumberAsc() {
    episodes.sort((a, b) {
      return a.number.compareTo(b.number);
    });
  }

  void _sortByEpisodeNumberDesc() {
    episodes.sort((a, b) {
      return b.number.compareTo(a.number);
    });
  }

  // 未完成的靠前，完成的按number升序排序
  void _sortByUnCheckedFront() {
    _sortByEpisodeNumberAsc(); // 先按number升序排序
    episodes.sort((a, b) {
      int ac, bc;
      ac = a.isChecked() ? 1 : 0;
      bc = b.isChecked() ? 1 : 0;
      // 双方都没有完成或都完成(状态一致)时，按number升序排序
      if (a.isChecked() == b.isChecked()) {
        return a.number.compareTo(b.number);
      } else {
        // 否则未完成的靠前
        return ac.compareTo(bc);
      }
    });
  }
}
