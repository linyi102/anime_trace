import 'package:animetrace/modules/sort_mode/controller.dart';
import 'package:animetrace/modules/sort_mode/mode.dart';
import 'package:animetrace/utils/extensions/list.dart';
import 'package:animetrace/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/dao/label_dao.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:get/get.dart';
import 'package:pinyin/pinyin.dart';

import '../models/label.dart';

class LabelsController extends GetxController {
  static LabelsController get to => Get.find();

  // 所有标签
  RxList<Label> labels = RxList.empty();

  // 文本输入控制器，放在这里是为了避免重绘时丢失
  var inputKeywordController = TextEditingController();
  String get searchKeyword => inputKeywordController.text;

  // 搜索输入关键字(因为搜索后退出标签管理界面时，labels不再是数据库全部标签，所以再进入时要显示当前关键字)
  String kw = "";

  late final sortModeController = SortModeController<Label>(
    modes: [
      SortMode(label: '创建时间', storeIndex: 0, sort: _sortByCreated),
      SortMode(label: '名称', storeIndex: 1, sort: _sortByName),
    ],
    defaultModeIndex: SettingsUtil.get(SettingsEnum.labelSortMode),
    defaultReverse: SettingsUtil.get(SettingsEnum.labelSortReverse),
    getOriList: () => labels,
    onSorted: (sortedList) => labels.value = sortedList,
    onModeChanged: (mode) =>
        SettingsUtil.set(SettingsEnum.labelSortMode, mode.storeIndex),
    onReverseChanged: (isReverse) =>
        SettingsUtil.set(SettingsEnum.labelSortReverse, isReverse),
  );

  List<String> get recommendedLabels => [
        "🔮魔法",
        "🏀运动",
        "💖爱情",
        "💘恋爱",
        "🏫校园",
        "🔍推理",
        "👻恐怖",
        "🎮游戏",
        "⚔战斗",
        "🎵音乐",
        "🎞️剧场版",
        "🍜泡面番",
        "🌟我想推荐",
        "👍他人推荐",
        "百合",
        "3D",
        "悬疑",
        "架空",
        "异世界",
        "妹系",
        "热血",
        "冒险",
        "后宫",
        "搞笑",
        "日常",
        "轻松",
        "催泪",
        "治愈",
        "致郁",
        "GAL改",
        "游戏改",
        "轻小说改",
        "偶像",
        "神作",
        "长篇",
        "剧情向",
        "半年番",
        "国漫",
        "欧美",
        "日漫",
        "韩漫",
        "芳文社",
        "动画工房",
        "MADHouse",
        "MAPPA",
      ];

  int unAddedRecommendedLabelCount() {
    int count = 0;
    for (var i = 0; i < recommendedLabels.length; i++) {
      if (labels.indexWhere((e) => e.name == recommendedLabels[i]) < 0) {
        count++;
      }
    }
    return count;
  }

  @override
  void onInit() {
    super.onInit();
    getAllLabels();
  }

  @override
  void dispose() {
    inputKeywordController.dispose();
    sortModeController.dispose();
    super.dispose();
  }

  // 还原数据后，需要重新获取所有标签
  void getAllLabels() async {
    final allLabels = await LabelDao.getAllLabels();
    _sortLabels(allLabels);
  }

  void _sortLabels(List<Label> labels) {
    this.labels.value = labels;
    sortModeController.sort();
  }

  Future<bool> addLabel(String labelName) async {
    Label newLabel = Label(0, labelName);
    int newId = await LabelDao.insert(newLabel);
    if (newId > 0) {
      Log.info("添加标签成功，新插入的id=$newId");
      // 指定新id，并添加到controller中
      newLabel.id = newId;
      if (searchKeyword.isEmpty) {
        // 没在搜索，直接添加
        labels.add(newLabel);
        _sortLabels(labels);
      } else {
        // 如果在搜索后添加，则看是否存在关键字，如果有，则添加到labels里(此时controller里的labels存放的是搜索结果)
        if (newLabel.name.contains(searchKeyword)) {
          labels.add(newLabel);
          _sortLabels(labels);
        }
      }
      return true;
    } else {
      ToastUtil.showText('添加失败');
      return false;
    }
  }

  Future<bool> updateLabel(Label label, String newLabelName) async {
    int index = labels.indexOf(label);

    int updateCnt = await LabelDao.update(label.id, newLabelName);
    if (updateCnt > 0) {
      Log.info("修改标签成功");
      // 修改controller里的该标签的名字
      // labelsController.labels[index].name = newLabelName; // 无效
      label.name = newLabelName;
      labels[index] = label; // 必须要重新赋值，才能看到变化
      _sortLabels(labels);

      return true;
    } else {
      ToastUtil.showText("修改标签失败");
      return false;
    }
  }
}

List<Label> _sortByCreated(List<Label> labels, bool isReverse) {
  final sorted = labels.sorted((a, b) => a.id.compareTo(b.id));
  return isReverse ? sorted.reversed.toList() : sorted;
}

List<Label> _sortByName(List<Label> labels, bool isReverse) {
  String coverPinyin(String str) =>
      PinyinHelper.getPinyinE(str, separator: '', defPinyin: '');
  final sorted = labels.sorted(
    (a, b) => coverPinyin(a.nameWithoutEmoji.toLowerCase())
        .compareTo(coverPinyin(b.nameWithoutEmoji.toLowerCase())),
  );
  return isReverse ? sorted.reversed.toList() : sorted;
}
