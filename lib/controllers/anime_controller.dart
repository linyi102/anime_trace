import 'package:flutter/material.dart';
import 'package:flutter_test_future/dao/anime_label_dao.dart';
import 'package:flutter_test_future/dao/note_dao.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/episode.dart';
import 'package:flutter_test_future/models/label.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:get/get.dart';

class AnimeController extends GetxController {
  /////////////////////////////// 数据 ///////////////////////////////
  var anime = Anime(animeName: "", animeEpisodeCnt: 0).obs;
  bool get isCollected => anime.value.isCollected();

  List<Episode> episodes = []; // 集
  List<Note> notes = []; // 集对应的笔记
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
  var rateNoteCount = 0.obs;

  /////////////////////////////// 方法 ///////////////////////////////

  // 删除动漫，需要清空集信息、笔记、标签
  void deleteAnime() {
    anime.update((val) {
      val?.animeId = 0;
      val?.checkedEpisodeCnt = 0;
      val?.tagName = "";
      // 保留其他信息
    });

    episodes.clear();
    loadEpisodeOk = false;
    update(episodeBuilderIds);

    labels.clear();
    notes.clear();
    mapSelected.clear();
  }

  // 退出动漫详情页，清空信息
  void popPage() {
    anime.value = Anime(animeName: "", animeEpisodeCnt: 0);

    episodes.clear();
    loadEpisodeOk = false;
    notes.clear();
    multiSelected.value = false;
    mapSelected.clear();
    lastMultiSelectedIndex = -1;
    currentStartEpisodeNumber = 1;
    rateNoteCount.value = 0;
  }

  void setAnime(Anime newAnime) {
    anime.value = Anime(animeName: "", animeEpisodeCnt: 0);
    // 进入详细页可以看到变化
    anime.value = newAnime;
    // 下面方式可以实时更新播放状态，但进入详细页仍然是之前的动漫
    // anime.update((val) => val = newAnime);
  }

  // 获取评价数量
  void acqRateNoteCount() async {
    if (isCollected) {
      rateNoteCount.value =
          await NoteDao.getRateNoteCountByAnimeId(anime.value.animeId);
    }
  }

  // 获取添加的标签
  void acqLabels() async {
    labels.clear();
    if (isCollected) {
      Log.info("查询当前动漫(id=${anime.value.animeId})的所有标签");
      labels
          .addAll(await AnimeLabelDao.getLabelsByAnimeId(anime.value.animeId));
    }
  }

  void turnShowDescInAnimeDetailPage() {
    showDescInAnimeDetailPage.value = !showDescInAnimeDetailPage.value;
    SpProfile.turnShowDescInAnimeDetailPage();
  }

  List<Object> episodeBuilderIds = ["getbuilder_episode"];
  void loadEpisode() async {
    // 重置，然后重新渲染
    loadEpisodeOk = false;
    episodes.clear();
    notes.clear();
    update(episodeBuilderIds);

    // 加载集信息
    // await Future.delayed(const Duration(seconds: 1));
    if (anime.value.animeEpisodeCnt == 0) {
      // 如果为0，则不修改currentStartEpisodeNumber
    } else if (currentStartEpisodeNumber > anime.value.animeEpisodeCnt) {
      // 起始集编号>动漫集数，则从最后一个范围开始x
      // 修改后集数为260，则(260/50)=5.2=5, 5*50=250, 250+1=251
      // 修改后集数为250，则(250/50)=5，(5-1)*50=200, 200+1=201，也就是251-50
      currentStartEpisodeNumber =
          anime.value.animeEpisodeCnt ~/ episodeRangeSize * episodeRangeSize +
              1;
      if (anime.value.animeEpisodeCnt % episodeRangeSize == 0) {
        currentStartEpisodeNumber -= episodeRangeSize;
      }
    }
    episodes = await SqliteUtil.getEpisodeHistoryByAnimeIdAndRange(
        anime.value,
        currentStartEpisodeNumber,
        currentStartEpisodeNumber + episodeRangeSize - 1);
    Log.info("削减后，集长度为${episodes.length}");
    _sortEpisodes(SPUtil.getString("episodeSortMethod",
        defaultValue: sortMethods[0])); // 排序，默认升序，兼容旧版本

    for (var episode in episodes) {
      Note episodeNote = Note(
          anime: anime.value,
          episode: episode,
          relativeLocalImages: [],
          imgUrls: []);
      if (episode.isChecked()) {
        // 如果该集完成了，就去获取该集笔记（内容+图片）
        episodeNote = await NoteDao
            .getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(
                episodeNote);
        // Log.info(
        //     "第${episodeNote.episode.number}集的图片数量: ${episodeNote.relativeLocalImages.length}");
      }
      notes.add(episodeNote);
    }
    loadEpisodeOk = true;
    update(episodeBuilderIds);
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
        SqliteUtil.updateHistoryItem(anime.value.animeId, episodeNumber,
            dateTime, anime.value.reviewNumber);
      } else {
        SqliteUtil.insertHistoryItem(anime.value.animeId, episodeNumber,
            dateTime, anime.value.reviewNumber);
        // 同时插入空笔记，记得获取最新插入的id，否则进入的是笔记0，会造成修改笔记无效
        Note episodeNote = Note(
            anime: anime.value,
            episode: episodes[episodeIndex],
            relativeLocalImages: [],
            imgUrls: []);
        // 如果存在，恢复之前做的笔记。(完成该集并添加笔记后，又完成该集，需要恢复笔记)
        () async {
          notes[episodeIndex] = await NoteDao
              .getEpisodeNoteByAnimeIdAndEpisodeNumberAndReviewNumber(
                  episodeNote);
        }(); // 只让恢复笔记作为异步，如果让forEach中的函数作为异步，则可能会在改变所有时间前退出多选模式
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
      firstDate: DateTime(1986),
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

  /////////////////////////////// 更新anime ///////////////////////////////

  //  其他页面(例如详情页修改了动漫封面)更新动漫时，动漫详细页可以收到通知并重新渲染
  updateAnimeUrl(String animeUrl) {
    anime.update((anime) {
      anime?.animeUrl = animeUrl;
    });
  }

  updateAnimeCoverUrl(String coverUrl) {
    anime.update((anime) {
      anime?.animeCoverUrl = coverUrl;
    });
  }

  updateAnimeName(String newName) {
    anime.update((anime) {
      anime?.animeName = newName;
    });
  }

  updateAnimeNameAnother(String newNameAnother) {
    anime.update((anime) {
      anime?.nameAnother = newNameAnother;
    });
  }

  updateAnimeDesc(String newDesc) {
    anime.update((anime) {
      anime?.animeDesc = newDesc;
    });
  }

  updateAnimePlayStatus(String playStatus) {
    anime.update((anime) {
      anime?.playStatus = playStatus;
    });
  }

  updateAnimeEpisodeCnt(int cnt) {
    anime.update((anime) {
      anime?.animeEpisodeCnt = cnt;
    });
  }

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
        List<Widget> radioList = [];
        for (int i = 0; i < sortMethods.length; ++i) {
          radioList.add(
            ListTile(
              title: Text(sortMethodsName[i]),
              leading: sortMethods[i] == SPUtil.getString("episodeSortMethod")
                  ? Icon(
                      Icons.radio_button_on_outlined,
                      color: ThemeUtil.getPrimaryColor(),
                    )
                  : const Icon(
                      Icons.radio_button_off_outlined,
                    ),
              onTap: () {
                Log.info("修改排序方式为${sortMethods[i]}");
                _sortEpisodes(sortMethods[i]);
                // 退出对话框
                Navigator.pop(context);
                // 更新
                update();
              },
            ),
          );
        }
        return AlertDialog(
          title: const Text('排序方式'),
          content: SingleChildScrollView(
            child: Column(
              children: radioList,
            ),
          ),
        );
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

    // 更新
    update(episodeBuilderIds);
  }

  void _sortByEpisodeNumberAsc() {
    episodes.sort((a, b) {
      return a.number.compareTo(b.number);
    });
    notes.sort((a, b) {
      return a.episode.number.compareTo(b.episode.number);
    });
  }

  void _sortByEpisodeNumberDesc() {
    episodes.sort((a, b) {
      return b.number.compareTo(a.number);
    });
    notes.sort((a, b) {
      return b.episode.number.compareTo(a.episode.number);
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
    notes.sort((a, b) {
      int ac, bc;
      ac = a.episode.isChecked() ? 1 : 0;
      bc = b.episode.isChecked() ? 1 : 0;
      // 双方都没有完成或都完成(状态一致)时，按number升序排序
      if (a.episode.isChecked() == b.episode.isChecked()) {
        return a.episode.number.compareTo(b.episode.number);
      } else {
        // 否则未完成的靠前
        return ac.compareTo(bc);
      }
    });
  }
}
