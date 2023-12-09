import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/dao/anime_label_dao.dart';
import 'package:flutter_test_future/dao/episode_desc_dao.dart';
import 'package:flutter_test_future/dao/note_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/episode.dart';
import 'package:flutter_test_future/models/label.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';

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

  // 是否支持播放
  bool get supportPlayVideo =>
      ClimbAnimeUtil.getClimbWebsiteByAnimeUrl(anime.animeUrl)
          ?.supportPlayVideo ??
      false;

  // 当前播放的集
  Episode? curPlayEpisode;

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
    // 收藏动漫后，需要显示集信息，因此还要更新detailPageId
    update([episodeId, detailPageId]);
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

  void showDialogmodifyEpisodeCnt(BuildContext context) {
    if (!isCollected) return;

    dialogSelectUint(context, "集数",
            initialValue: anime.animeEpisodeCnt,
            // 传入已有的集长度而非_anime.animeEpisodeCnt，是为了避免更新动漫后，_anime.animeEpisodeCnt为0，然后点击修改集数按钮，弹出对话框，传入初始值0，如果点击了取消，就会返回初始值0，导致集数改变
            // initialValue: initialValue,
            // 添加选择集范围后，就不能传入已有的集长度了。
            // 最终解决方法就是当爬取的集数小于当前集数，则不进行修改，所以这里只管传入当前动漫的集数
            minValue: 0,
            maxValue: 2000)
        .then((value) {
      if (value == null) {
        Log.info("未选择，直接返回");
        return;
      }
      // if (value == _episodes.length) {
      if (value == anime.animeEpisodeCnt) {
        Log.info("设置的集数等于初始值${anime.animeEpisodeCnt}，直接返回");
        return;
      }
      int episodeCnt = value;
      AnimeDao.updateEpisodeCntByAnimeId(anime.animeId, episodeCnt)
          .then((value) {
        // 修改数据
        anime.animeEpisodeCnt = episodeCnt;
        // 重绘
        updateAnimeInfo(); // 重绘信息行中显示的集数
        loadEpisode(); // 重绘集信息
      });
    });
  }

  bool climbing = false;

  Future<bool> climbAnimeInfo(BuildContext context) async {
    if (anime.animeUrl.isEmpty) {
      if (anime.isCollected()) ToastUtil.showText("无法更新自定义动漫");
      return false;
    }
    if (climbing) {
      if (anime.isCollected()) ToastUtil.showText("正在获取信息");
      return false;
    }
    // if (_anime.isCollected()) ToastUtil.showText("更新中");
    climbing = true;
    update([episodeId]);

    // oldAnime、newAnime、_anime引用的是同一个对象，修改后无法比较，因此需要先让oldAnime引用深拷贝的_anime
    // 因为更新时会用到oldAnime的id、tagName、animeEpisodeCnt，所以只深拷贝这些成员
    Anime oldAnime = anime.copyWith();
    // 需要传入_anime，然后会修改里面的值，newAnime也会引用该对象
    Log.info("_anime.animeEpisodeCnt = ${anime.animeEpisodeCnt}");
    Anime newAnime = await ClimbAnimeUtil.climbAnimeInfoByUrl(anime);
    // 如果更新后动漫集数比原来的集数小，则不更新集数
    // 目的是解决一个bug：东京喰种PINTO手动设置集数为2后，更新动漫，获取的集数为0，集数更新为0后，此时再次手动修改集数，因为传入的初始值为0，即使按了取消，由于会返回初始值0，因此会导致集数变成了0
    // 因此，只要用户设置了集数，即使更新的集数小，也会显示用户设置的集数，只有当更新集数大时，才会更新。
    // 另一种解决方式：点击修改集数按钮时，传入此时_episodes的长度，而不是_anime.animeEpisodeCnt，这样就保证了传入给修改集数对话框的初始值为原来的集数，而不是更新的集数。
    Log.info("_anime.animeEpisodeCnt = ${anime.animeEpisodeCnt}");
    if (newAnime.animeEpisodeCnt < anime.animeEpisodeCnt) {
      newAnime.animeEpisodeCnt = anime.animeEpisodeCnt;
    }
    // 如果某些信息不为空，则不更新这些信息，避免覆盖用户修改的信息
    // 不包括名称、播放状态、动漫链接、封面链接
    if (oldAnime.nameAnother.isNotEmpty) {
      newAnime.nameAnother = oldAnime.nameAnother;
    }
    if (oldAnime.area.isNotEmpty) {
      newAnime.area = oldAnime.area;
    }
    if (oldAnime.category.isNotEmpty) {
      newAnime.category = oldAnime.category;
    }
    if (oldAnime.premiereTime.isNotEmpty) {
      newAnime.premiereTime = oldAnime.premiereTime;
    }
    if (oldAnime.animeDesc.isNotEmpty) {
      newAnime.animeDesc = oldAnime.animeDesc;
    }

    if (anime.isCollected()) {
      // 如果收藏了，才去更新
      bool updateCover = false;
      // 提示是否更新封面
      if (oldAnime.animeCoverUrl != newAnime.animeCoverUrl) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("发现新封面"),
            content: const Text("检测到新封面，是否更新？"),
            actions: [
              TextButton(
                onPressed: () {
                  final imageProvider =
                      Image.network(newAnime.animeCoverUrl).image;

                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => PhotoView(
                          imageProvider: imageProvider,
                          onTapDown: (_, __, ___) =>
                              Navigator.of(context).pop())));
                },
                child: const Text("预览"),
              ),
              TextButton(
                onPressed: () {
                  updateCover = false;
                  Navigator.pop(context);
                },
                child: const Text("跳过"),
              ),
              TextButton(
                onPressed: () {
                  updateCover = true;
                  Navigator.pop(context);
                },
                child: const Text("更新"),
              )
            ],
          ),
        );
      }

      AnimeDao.updateAnime(oldAnime, newAnime, updateCover: updateCover)
          .then((value) {
        // 如果集数变大，则重新加载页面。且插入到更新记录表中，然后重新获取所有更新记录，便于在更新记录页展示
        if (newAnime.animeEpisodeCnt > oldAnime.animeEpisodeCnt) {
          loadEpisode();
          // animeController.updateAnimeEpisodeCnt(newAnime.animeEpisodeCnt);
          // 调用控制器，添加更新记录到数据库并更新内存数据
          final UpdateRecordController updateRecordController = Get.find();
          updateRecordController.updateSingleAnimeData(oldAnime, newAnime);
        }
      });
    }
    climbing = false;
    updateAnime(newAnime);
    update([episodeId]);

    return true;
  }

  playEpisode(Episode episode) {
    curPlayEpisode = episode;
    update();
  }

  /// 关闭左侧视频区域
  closeEpisodePlayPage() {
    curPlayEpisode = null;
    update();
  }

  bool rightDetailScreenIsFolded = false;

  foldOrUnfoldRightDetailScreen() {
    if (rightDetailScreenIsFolded) {
      unfoldRightDetailScreen();
    } else {
      foldRightDetailScreen();
    }
  }

  /// 折叠右侧详情区域
  foldRightDetailScreen() {
    rightDetailScreenIsFolded = true;
    update();
  }

  /// 展开右侧详情区域
  unfoldRightDetailScreen() {
    rightDetailScreenIsFolded = false;
    update();
  }
}
